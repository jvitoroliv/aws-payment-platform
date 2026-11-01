#!/usr/bin/env python3
"""
Script to update CIDR blocks in Splunk dashboard JSON files using templates.

This script reads the CIDR mappings from cidrs_blocks_by_name.json and generates
Splunk dashboard JSON files from templates with the latest CIDR data.
"""

import json
import sys
from pathlib import Path


def load_cidr_mappings(cidr_file_path):
    """Load CIDR mappings from the JSON file."""
    # Error boundary — failures here are logged and handled, not propagated
    try:
        with open(cidr_file_path, 'r', encoding='utf-8') as f:
            return json.load(f)
    except FileNotFoundError:
        print(f"Error: CIDR mappings file not found: {cidr_file_path}")
        sys.exit(1)
    except json.JSONDecodeError as e:
        print(f"Error: Invalid JSON in CIDR mappings file: {e}")
        sys.exit(1)


def generate_cidrmatch_section(cidr_mappings):
    """Generate the cidrmatch section from CIDR mappings."""
    lines = []

    for label, cidrs in cidr_mappings.items():
        for cidr in cidrs:
            # Escape quotes for JSON string
            escaped_label = label.replace('"', '\\"')
            lines.append(f'  cidrmatch(\\"{cidr}\\", client_ip), \\"{escaped_label}\\",')

    # Add the default case
    lines.append('  1=1, \\"Unknown - \\" + client_ip')

    return '\\n'.join(lines)


def process_template(template_path, output_path, cidr_mappings):
    """Process a template file and generate the output file."""
    try:
        with open(template_path, 'r', encoding='utf-8') as f:
            template_content = f.read()

        cidrmatch_section = generate_cidrmatch_section(cidr_mappings)
        updated_content = template_content.replace('{{CIDRMATCH_SECTION}}', cidrmatch_section)

        with open(output_path, 'w', encoding='utf-8') as f:
            f.write(updated_content)

        print(f"Generated: {output_path}")
        return True

    # Catch-all with structured logging. Specific exceptions handled above.
    except Exception as e:
        print(f"Error processing {template_path}: {e}")
        return False


def main():
    # Define paths (Docker environment)
    cidr_file = Path('/app/configurations/allowlists/cidrs_blocks_by_name.json')
    splunk_dir = Path('/app/splunk')

    # Check if files exist
    if not cidr_file.exists():
        print(f"Error: CIDR mappings file not found: {cidr_file}")
        sys.exit(1)

    if not splunk_dir.exists():
        print(f"Error: Splunk directory not found: {splunk_dir}")
        sys.exit(1)

    # Find all template files
    template_files = list(splunk_dir.glob("*.json.template"))

    if not template_files:
        print(f"No template files found in {splunk_dir}")
        sys.exit(1)

    print(f"\nFound {len(template_files)} template files to process")

    # Load CIDR mappings
    print(f"Loading CIDR mappings from: {cidr_file}")
    cidr_mappings = load_cidr_mappings(cidr_file)
    print(f"Loaded {len(cidr_mappings)} CIDR mapping groups:")
    for label, cidrs in cidr_mappings.items():
        print(f"  {label}: {len(cidrs)} CIDRs")

    # Process each template file
    success_count = 0
    for template_file in template_files:
        output_filename = template_file.name.replace('.template', '')
        output_path = splunk_dir / output_filename

        print(f"\nProcessing: {template_file.name} -> {output_filename}")
        if process_template(template_file, output_path, cidr_mappings):
            success_count += 1

    print(f"\nCompleted processing {success_count}/{len(template_files)} files successfully")

if __name__ == "__main__":
    main()
