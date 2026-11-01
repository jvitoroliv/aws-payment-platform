# Security Group Rules Comparison Tool

A tool to compare security group rules between two groups of AWS security groups.
This tool provides comparison at the individual rule component level, showing which CIDRs, prefix lists, or source security groups differ between rule sets.

## Files

- `compare_sg_rules.py` - The main Python script that retrieves and compares rules
- `Dockerfile` - Docker image containing Python dependencies to make Docker the only required dependency to install
- `sg-compare.sh` - Wrapper script to run the Python script in Docker
- `env-sg-compare-PROJ-11856.sh` - Wrapper script for running comparisons between existing security groups. Only valid for security groups which were present at the time PROJ-11856 was in progress.

## Prerequisites

- Docker installed
- AWS credentials configured

## Usage

```bash
# Show help
./sg-compare.sh

# Compare ingress rules using security group names
./sg-compare.sh --source-sgs web-servers app-tier --target-sgs new-web-servers new-app-tier

# Compare egress rules
./sg-compare.sh --source-sgs web-sg --target-sgs new-app --rule-type egress

## Environment-Based Comparisons

# Compare dev us-east-1 security groups (default)
./env-sg-compare-PROJ-11856.sh dev

# Compare prod us-west-2 security groups  
./env-sg-compare-PROJ-11856.sh prod us-west-2

# Compare stage with allowlist instead of security groups
./env-sg-compare-PROJ-11856.sh stage us-east-1 sg-to-allowlist

# Show help for the consolidated script
./env-sg-compare-PROJ-11856.sh
```

## Output

The tool provides a **unified diff-style output** similar to git diff, showing all rule components in a single table:

Prefix:
- **`-`** : Rule components only in SOURCE security groups
- **`+`** : Rule components only in TARGET security groups  
- **` `** : Rule components in both SOURCE and TARGET security groups

Each rule component shows:
- **Protocol** (TCP, UDP, ICMP, All)
- **Port range** or "All"
- **Source Type** (cidr, prefix_list, security_group)
- **Source Value** (the actual CIDR block, prefix list ID, or security group ID)

### Example Output:
```
diff --sg-rules web-servers,app-tier new-web-servers,new-app-tier
ingress rules: 2 deletions(-), 1 insertion(+), 3 unchanged

   Proto  | Ports      | Source Type  | Source Value
------------------------------------------------------------------------
-  TCP    | 443        | cidr         | CIDR: 10.0.1.0/24
+  TCP    | 443        | cidr         | CIDR: 10.0.2.0/24
   TCP    | 443        | cidr         | CIDR: 10.0.3.0/24
-  TCP    | 80         | security_group| SG: sg-123abc
   TCP    | 22         | cidr         | CIDR: 192.168.1.0/24
   UDP    | 53         | cidr         | CIDR: 0.0.0.0/0
```
