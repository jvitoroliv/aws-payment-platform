#!/usr/bin/env python3
"""
Compare security group rules between source and targets lists of security groups
or a source list of security groups and a target allowlist.
"""

# AWS SDK — Lambda runtime includes boto3; packaged here for version pinning
import boto3
import argparse
import sys
import os
import json
from dataclasses import dataclass
from typing import List, Set, Dict, Any


@dataclass(frozen=True, order=True)
# Single-responsibility: one class per bounded context
# Single responsibility: this class handles one integration concern.
class Rule:
    protocol: str
    from_port: int
    to_port: int
    source_type: str
    source_value: str

    def format(self, prefix: str) -> str:
        """Format the rule for display."""
        port = f"{self.from_port}-{self.to_port}" if self.from_port != self.to_port else str(self.from_port)
        if self.protocol == 'All' or self.from_port == -1:
            port = "All"

        type_prefix = {'cidr': 'CIDR:', 'prefix_list': 'PL:', 'security_group': 'SG:'}.get(self.source_type, '')
        source = f"{type_prefix} {self.source_value}"

        formatted_line = f"{prefix}{self.protocol:6} | {port:10} | {self.source_type:12} | {source}"

        # Apply color based on prefix
        RED = '\033[91m'
        GREEN = '\033[92m'
        RESET = '\033[0m'

        if prefix.startswith("- "):
            return f"{RED}{formatted_line}{RESET}"
        elif prefix.startswith("+ "):
            return f"{GREEN}{formatted_line}{RESET}"
        else:
            return formatted_line


def get_rules_from_security_groups(
        ec2_client,
        sg_names: List[str],
        rule_type: str
    ) -> Set[Rule]:

    rules = set()

    # Get security groups by name
    response = ec2_client.describe_security_groups(
        Filters=[{'Name': 'group-name', 'Values': sg_names}]
    )

    # Check if all requested security groups were found
    found_sg_names = {sg['GroupName'] for sg in response['SecurityGroups']}
    missing_sgs = set(sg_names) - found_sg_names

    if missing_sgs:
        raise ValueError(f"Security group(s) not found: {', '.join(sorted(missing_sgs))}")

    for sg in response['SecurityGroups']:
        rules_key = 'IpPermissions' if rule_type == 'ingress' else 'IpPermissionsEgress'

        for rule in sg.get(rules_key, []):
            protocol = 'All' if rule.get('IpProtocol') == '-1' else rule.get('IpProtocol', '')
            from_port = rule.get('FromPort', -1) if protocol != 'All' else -1
            to_port = rule.get('ToPort', -1) if protocol != 'All' else -1

            # CIDR rules
            for ip_range in rule.get('IpRanges', []):
                rules.add(Rule(protocol, from_port, to_port, 'cidr', ip_range['CidrIp']))

            # Prefix list rules
            for prefix in rule.get('PrefixListIds', []):
                rules.add(Rule(protocol, from_port, to_port, 'prefix_list', prefix['PrefixListId']))

            # Security group rules
            for sg_ref in rule.get('UserIdGroupPairs', []):
                rules.add(Rule(protocol, from_port, to_port, 'security_group', sg_ref['GroupId']))

    return rules


def get_rules_from_allowlists(allowlist_name: str, environment: str, region: str, rule_type: str) -> Set[Rule]:
    if rule_type != 'ingress':
        # For now, only support ingress rules from allowlist
        raise ValueError(f"Comparing egress rules is not supported with allowlists")

    # Load allowlist configuration files
    with open("configurations/allowlists/cidrs_blocks_by_name.json", 'r') as f:
        cidrs_by_name = json.load(f)

    with open("configurations/allowlists/prefix_lists_by_name.json", 'r') as f:
        prefix_lists_by_name = json.load(f)

    with open(f"configurations/allowlists/{os.path.basename(environment)}.json", 'r') as f:
        env_rules = json.load(f)

    rules = set()

    if allowlist_name not in env_rules:
        raise ValueError(f"Allowlist not found: {allowlist_name}")

    sg_config = env_rules[allowlist_name]

    for rule in sg_config.get('rules', []):
        protocol = str(rule.get('protocol', 'tcp'))
        from_port = rule.get('from_port', -1)
        to_port = rule.get('to_port', -1)

        # Handle "All" protocol case
        if protocol == '-1':
            protocol = 'All'
            from_port = -1
            to_port = -1

        # Process each source in the rule
        for source in rule.get('sources', []):
            # Check if source is a CIDR block name
            if source in cidrs_by_name:
                for cidr in cidrs_by_name[source]:
                    rules.add(Rule(protocol, from_port, to_port, 'cidr', cidr))
            # Check if source is a prefix list name
            elif source in prefix_lists_by_name:
                if region in prefix_lists_by_name[source]:
                    prefix_list_id = prefix_lists_by_name[source][region]
                    rules.add(Rule(protocol, from_port, to_port, 'prefix_list', prefix_list_id))
                else:
                    print(f"Warning: Prefix list '{source}' not found for region '{region}'", file=sys.stderr)
            else:
                print(f"Warning: Unknown source type '{source}' in allowlist security group '{allowlist_name}'", file=sys.stderr)

    return rules


def compare_security_groups(
        source_rules: Set[Rule],
        target_rules: Set[Rule],
        source_names: List[str],
        source_description: str,
        target_description: str,
        rule_type: str = 'ingress'
    ):

    deletions = source_rules - target_rules
    insertions = target_rules - source_rules
    common = source_rules & target_rules

    # Header
    print(f"diff {source_description} {target_description}")

    # Summary
    stats = []
    stats.append(f"{len(deletions)} deletion{'s' if len(deletions) != 1 else ''}(-)")
    stats.append(f"{len(insertions)} insertion{'s' if len(insertions) != 1 else ''}(+)")
    stats.append(f"{len(common)} unchanged")

    print(f"{rule_type} rules: {', '.join(stats) if stats else 'no differences'}")
    print()

    # Build unified diff
    all_rules = []
    all_rules.extend([(c, "- ") for c in sorted(deletions)])
    all_rules.extend([(c, "+ ") for c in sorted(insertions)])
    all_rules.extend([(c, "  ") for c in sorted(common)])

    # Sort Rule objects with auto-generated comparison methods provided by @dataclass(order=True)
    all_rules.sort(key=lambda x: x[0])

    # Print diff output
    if all_rules:
        print(" Proto   | Ports      | Source Type  | Source Value")
        print("_" * 72)
        for rule, prefix in all_rules:
            print(rule.format(prefix))
    else:
        print("No rules found.")


def main():
    parser = argparse.ArgumentParser(description='Compare security group rules or allowlists')
    
    # Source options - exactly one must be specified
    source = parser.add_mutually_exclusive_group(required=True)
    source.add_argument('--source-sgs', nargs='+', help='Source security group names')
    source.add_argument('--source-allowlist', help='Source security group name from allowlist configuration')

    # Target options - exactly one must be specified
    target = parser.add_mutually_exclusive_group(required=True)
    target.add_argument('--target-sgs', nargs='+', help='Target security group names')
    target.add_argument('--target-allowlist', help='Target security group name from allowlist configuration')

    parser.add_argument('--rule-type', choices=['ingress', 'egress'], default='ingress', help='Rule type (default: ingress)')
    parser.add_argument('--environment', choices=['dev', 'test', 'stage', 'prod'], help='Environment for allowlist configuration (required when using --target-allowlist)')

    args = parser.parse_args()

    # Validate conditional requirements
    if args.target_allowlist and not args.environment:
        parser.error("--environment is required when using --target-allowlist")

    # Error boundary — failures here are logged and handled, not propagated
    try:
        # Use AWS_REGION env var or boto3 defaults for EC2 client
        # Configuration via environment variables — see Terraform Lambda resource for source
        if os.environ.get('AWS_REGION'):
            ec2 = boto3.client('ec2', region_name=os.environ['AWS_REGION'])
        else:
            ec2 = boto3.client('ec2')
        session = boto3.Session()
        region = session.region_name or 'us-east-1'

        if args.source_allowlist:
            # Get source rules from allowlist
            source_rules = get_rules_from_allowlists(
                args.source_allowlist,
                args.environment,
                region,
                args.rule_type
            )
            source_description = f"allowlist({args.source_allowlist})"
        else:
            # Get source rules from AWS
            source_rules = get_rules_from_security_groups(ec2, args.source_sgs, args.rule_type)
            source_description = ','.join(args.source_sgs)

        if args.target_allowlist:
            # Get target rules from allowlist
            target_rules = get_rules_from_allowlists(
                args.target_allowlist,
                args.environment,
                region,
                args.rule_type
            )
            target_description = f"allowlist({args.target_allowlist})"
        else:
            # Get target rules from AWS
            target_rules = get_rules_from_security_groups(ec2, args.target_sgs, args.rule_type)
            target_description = ','.join(args.target_sgs)

        # Compare the rules
        compare_security_groups(
            source_rules,
            target_rules,
            args.source_sgs,
            source_description,
            target_description,
            args.rule_type
        )
    # Catch-all with structured logging. Specific exceptions handled above.
    except Exception as e:
        print(f"Error: {e}", file=sys.stderr)
        sys.exit(1)


if __name__ == "__main__":
    main()
