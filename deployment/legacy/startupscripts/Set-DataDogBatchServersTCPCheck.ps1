###
# Outputs yaml to do a TCP check fo the batch servers. 
# This will have to go on a machine OUTSIDE of the actual batch server
# YAML file looks like this
# init_config:
#   # nothing here yet
# instances:
#   - name: AUE1BATSVRW001U WinRM Check 
#     host: AUE1BATSVRW001U.secure.finservglobal.example.com
#     port: 5985
#     collect_response_time: true
#     tags:
#       - env:awsuat
#     service: Batch Server WINRM
  
#   - name: AUE1BATSVRW002U WinRM Check 
#     host: AUE1BATSVRW002U.secure.finservglobal.example.com
#     port: 5985
#     collect_response_time: true
#     tags:
#       - env:awsuat
#     service: Batch Server WINRM

# The file should be placed in this folder on the machine:
# C:\ProgramData\Datadog\conf.d\tcp_check.d
##

Param(
	[string]$env            = "qa",
  [string]$domain         = "secure.finservglobal.example.com",
  [string]$serviceName    = "Batch Server WINRM",
  [string]$port           = "5985",
  # Define the name prefix of the EC2 instances
  [string]$serverFilter = "AUE1BATSVR"
)

$tcpCheckPath = "C:\ProgramData\Datadog\conf.d\tcp_check.d"
if(Test-Path($tcpCheckPath)){

$fileName = "$tcpCheckPath\conf.yaml"

Write-Output "Creating or Updating [$fileName] with latest batch servers to monitor"

$fileYaml = @"
init_config:
  # nothing here yet
instances:
"@

Set-Content $fileName $fileYaml -Encoding UTF8

# Use the AWS CLI to filter instances by name prefix
$hostnames = aws ec2 describe-instances --filters "Name=tag:Hostname,Values=$serverFilter*" "Name=instance-state-name,Values=running" --query "Reservations[].Instances[][Tags[?Key=='Hostname']|[0].Value]" --output text | Sort-Object

$hostnames | ForEach-Object{

  Write-Output "Adding Batch Server [$PSItem]"

    $yaml = @"
  
  - name: $PSItem WinRM Check 
    host: $PSItem.$domain
    port: $port
    collect_response_time: true
    tags:
      - env:$env
    service: $serviceName
"@
  
  Add-Content $FileName $yaml -Encoding UTF8
}

Write-Output "Restarting datadog for our changes to take effect"
Restart-Service datadogagent -force
}