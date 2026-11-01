# Splunk Dashboards

The `update-splunk-cidrs` script will update the CIDR match sections of the dashboards with the latest content from the `configurations/allowlists/cidrs_blocks_by_name.json` file.

If changes need to be made to a dashboard please update the <dashboard>.json.template file and run the script to update the actual dashboard JSON file.

The JSON can be copied and pasted into the Splunk UI to update the dashboard in Splunk

## TAG Blocked VPC Flow Log Requests
[https://example-tenant.splunkcloud.com/en-GB/app/search/tag_-_vpc_flow_logs_-_blocked_requests](https://example-tenant.splunkcloud.com/en-GB/app/search/tag_-_vpc_flow_logs_-_blocked_requests)

Shows incoming requests to the TAG AWS VPCs that have been blocked.

Can be grouped by the name of request source, request source and destination IP or request source, source IP and destination IP.

There is an option to show requests from known sources only (this is the default) which allows filtering out the many requests that are always present from unknown external sources.

The output can also be further filtered down to only the request sources specified by a text input. E.g. “TAG VPC*” would only show requests from “TAG VPC Prod UE1” etc.

## TAG Endpoint Domain Name Usage (splunk/endpoint-domain-name-usage.json)
https://example-tenant.splunkcloud.com/en-GB/app/search/tag_-_endpoint_domain_name_usage

Shows incoming requests for all TAG endpoints at the AWS ALBs. Broken down by the domain name used by the request and the source of the request.


## TAG Imperva WAF (splunk/imperva-waf.json)
https://example-tenant.splunkcloud.com/en-GB/app/search/tag_-_imperva_waf

Shows incoming requests for the TAG Web endpoint at Imperva WAF and at the AWS ALB. Broken down by the source of the request and the status/outcome.

