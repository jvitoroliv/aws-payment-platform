# Splunk Dashboard CIDR Updater

Updates Splunk dashboard JSON files with the latest CIDR data from `configurations/allowlists/cidrs_blocks_by_name.json`.

## Files

- `update_splunk_cidrs.py` - The main Python script that generates dashboard files from templates
- `update-splunk-cidrs.sh` - Wrapper script to run the Python script in Docker

## Prerequisites

- Docker installed

## Usage

```bash
# Show help
./update-splunk-cidrs.sh --help

# Dry run - show what would be generated without making changes
./update-splunk-cidrs.sh --dry-run

# Generate updated dashboard files
./update-splunk-cidrs.sh
```

The script will:
1. Load CIDR mappings from `configurations/allowlists/cidrs_blocks_by_name.json`
2. Find all `.template` files in the `splunk/` directory
3. Regenerate corresponding JSON files in the `splunk/` directory
4. Replace `{{CIDRMATCH_SECTION}}` placeholders with current CIDR data

## Output

```
Loading CIDR mappings from: /app/configurations/allowlists/cidrs_blocks_by_name.json
Loaded 111 CIDR mapping groups:
  (external) Qualys External Scanners: 2 CIDRs
  Auth Gateway: 3 CIDRs
  ...

Found 1 template files to process

Processing: endpoint-domain-name-usage.json.template -> endpoint-domain-name-usage.json
Generated: /app/splunk/endpoint-domain-name-usage.json

Completed processing 1/1 files successfully
```

## Adding New Dashboards

1. Create a new `.json.template` file in the `templates/` directory
2. Replace the CIDR matching section with `{{CIDRMATCH_SECTION}}`
3. Run the script to generate the updated JSON file

## Template Format

Template files use a simple placeholder replacement system:

- `{{CIDRMATCH_SECTION}}` - Replaced with generated cidrmatch() statements based on current CIDR data

The generated cidrmatch section follows this format:
```
cidrmatch("10.0.0.0/8", client_ip), "Internal",
cidrmatch("192.168.0.0/16", client_ip), "Internal", 
1=1, "Unknown - " + client_ip
```
