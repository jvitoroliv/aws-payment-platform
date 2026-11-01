Param(
    [string]$regionabbrev = "uw2",
    [string]$environment,
    [string]$region = "us-west-2",
    [string]$instances,
    [string]$ftpDNS, # "cerberusadmin.stage.platform.example.com"
	[string]$rdsDNS,  # "cerberus-stats-db.stage.platform.example.com"
	[string]$rdsName # cerberus-stats-postgres
)

$environment = $environment.ToLower()
$instanceArray = $instances.Split(',') | sort # will ensure order of batch servers in the param

# Get instance Ids
$ftp1Id = (Get-EC2Instance -Region $region -Filter @{Name="tag:Hostname";Values="$($instanceArray[0])"},@{Name="instance-state-name";Value="running"}).Instances[0].InstanceId

Write-Host "FTP001 Instance:" $ftp1Id

# Get IPs for instances
$ftp1IP = (Get-EC2Instance -InstanceId $ftp1Id).Instances[0].PrivateIpAddress 

Write-Host "FTP001 IP:" $ftp1IP

# Get the hostedZoneId
$zoneDNS = $ftpDNS.Substring($ftpDNS.IndexOf('.') + 1) + "."
$hostedZoneId = (Get-R53HostedZonesByName | Where-Object {($_.Name -eq $zoneDNS) -and ($_.Config.PrivateZone -eq $true)}).Id
Write-Host "HostedZoneId:" $hostedZoneId

# Change requests, 1 per Route53 entry
$change1 = New-Object Amazon.Route53.Model.Change
$change1.Action = "UPSERT"
$change1.ResourceRecordSet = New-Object Amazon.Route53.Model.ResourceRecordSet
$change1.ResourceRecordSet.Name = $ftpDNS + "."
$change1.ResourceRecordSet.Type = "A"
$change1.ResourceRecordSet.TTL = 300
$change1.ResourceRecordSet.ResourceRecords.Add(@{Value=$ftp1IP})

# Run change commands
Edit-R53ResourceRecordSet -HostedZoneId $hostedZoneId -ChangeBatch_Change $change1

$rdsEndpoint = (Get-RDSDBInstance -Region $region -Filter @{Name="db-instance-id";Values="$rdsName"}).Endpoint.Address
Write-Host "RDS Endpoint:" $rdsEndpoint

# Now the Cerberus-Stats RDS db
$change1 = New-Object Amazon.Route53.Model.Change
$change1.Action = "UPSERT"
$change1.ResourceRecordSet = New-Object Amazon.Route53.Model.ResourceRecordSet
$change1.ResourceRecordSet.Name = $rdsDNS + "."
$change1.ResourceRecordSet.Type = "CNAME"
$change1.ResourceRecordSet.TTL = 300
$change1.ResourceRecordSet.ResourceRecords.Add(@{Value=$rdsEndpoint})

# Run change commands
Edit-R53ResourceRecordSet -HostedZoneId $hostedZoneId -ChangeBatch_Change $change1

Write-Host "Done!"