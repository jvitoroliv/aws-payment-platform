Param(
    [string]$regionabbrev = "uw2",
    [string]$environment,
    [string]$region = "us-west-2",
    [string]$instances
)

$environment = $environment.ToLower()
$fi = "finserv" # DNS for batch entries is FINSERV, may be shared so simply hardcoding this.  Can be changed to param at a later date if necessary.

$instanceArray = $instances.Split(',') | sort # will ensure order of batch servers in the param

# Get instance Ids
$batch1Id = (Get-EC2Instance -Region $region -Filter @{Name="tag:Hostname";Values="$($instanceArray[0])"},@{Name="instance-state-name";Value="running"}).Instances[0].InstanceId
$batch2Id = (Get-EC2Instance -Region $region -Filter @{Name="tag:Hostname";Values="$($instanceArray[1])"},@{Name="instance-state-name";Value="running"}).Instances[0].InstanceId
$batch3Id = (Get-EC2Instance -Region $region -Filter @{Name="tag:Hostname";Values="$($instanceArray[2])"},@{Name="instance-state-name";Value="running"}).Instances[0].InstanceId

Write-Host "Batch1 Instance:" $batch1Id
Write-Host "Batch2 Instance:" $batch2Id
Write-Host "Batch3 Instance:" $batch3Id

# Get IPs for instances
$batch1IP = (Get-EC2Instance -InstanceId $batch1Id).Instances[0].PrivateIpAddress 
$batch2IP = (Get-EC2Instance -InstanceId $batch2Id).Instances[0].PrivateIpAddress 
$batch3IP = (Get-EC2Instance -InstanceId $batch3Id).Instances[0].PrivateIpAddress 

Write-Host "Batch1 IP:" $batch1IP
Write-Host "Batch2 IP:" $batch2IP
Write-Host "Batch3 IP:" $batch3IP

# Get the hostedZoneId
$hostedZoneId = (Get-R53HostedZonesByName | Where-Object {($_.Name -eq "coreplatform$environment.$regionabbrev.finservglobal.example.com.") -and ($_.Config.PrivateZone -eq $true)}).Id
Write-Host "HostedZoneId:" $hostedZoneId

# Change requests, 1 per Route53 entry
$change1 = New-Object Amazon.Route53.Model.Change
$change1.Action = "UPSERT"
$change1.ResourceRecordSet = New-Object Amazon.Route53.Model.ResourceRecordSet
$change1.ResourceRecordSet.Name = "$fi-batch1.coreplatform$environment.$regionabbrev.finservglobal.example.com."
$change1.ResourceRecordSet.Type = "A"
$change1.ResourceRecordSet.TTL = 300
$change1.ResourceRecordSet.ResourceRecords.Add(@{Value=$batch1IP})

$change2 = New-Object Amazon.Route53.Model.Change
$change2.Action = "UPSERT"
$change2.ResourceRecordSet = New-Object Amazon.Route53.Model.ResourceRecordSet
$change2.ResourceRecordSet.Name = "$fi-batch2.coreplatform$environment.$regionabbrev.finservglobal.example.com."
$change2.ResourceRecordSet.Type = "A"
$change2.ResourceRecordSet.TTL = 300
$change2.ResourceRecordSet.ResourceRecords.Add(@{Value=$batch2IP})

$change3 = New-Object Amazon.Route53.Model.Change
$change3.Action = "UPSERT"
$change3.ResourceRecordSet = New-Object Amazon.Route53.Model.ResourceRecordSet
$change3.ResourceRecordSet.Name = "$fi-batch3.coreplatform$environment.$regionabbrev.finservglobal.example.com."
$change3.ResourceRecordSet.Type = "A"
$change3.ResourceRecordSet.TTL = 300
$change3.ResourceRecordSet.ResourceRecords.Add(@{Value=$batch3IP})

# Run change commands
Edit-R53ResourceRecordSet -HostedZoneId $hostedZoneId -ChangeBatch_Change $change1
Edit-R53ResourceRecordSet -HostedZoneId $hostedZoneId -ChangeBatch_Change $change2
Edit-R53ResourceRecordSet -HostedZoneId $hostedZoneId -ChangeBatch_Change $change3

Write-Host "Done!"