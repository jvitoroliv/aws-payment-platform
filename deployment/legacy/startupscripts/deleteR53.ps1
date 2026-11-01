Write-Host "Starting DeleteR53.ps1"
$hostedZone = (aws route53 list-hosted-zones-by-name --dns-name platform.example.com --max-items 1 | ConvertFrom-Json)."HostedZones"
$hostedZoneId = $hostedZone.Id.Replace("/hostedzone/","")
$hostedZoneName = "." + $hostedZone.Name
Write-Host "Hosted Zone Name: " $hostedZoneName
Write-Host "Hosted Zone Id: " $hostedZoneId

$instanceId = Invoke-WebRequest -UseBasicParsing http://169.254.169.254/latest/meta-data/instance-id
$instanceIP = Invoke-WebRequest -UseBasicParsing http://169.254.169.254/latest/meta-data/local-ipv4
$ec2Name = (aws ec2 describe-tags --filters "Name=resource-id,Values=$instanceId" | ConvertFrom-Json | Select-Object -ExpandProperty Tags | Where-Object Key -eq "Name").Value
$dns = ($ec2Name + $hostedZoneName).ToLower().Replace(" ","")
Write-Host "EC2 Name: " $ec2Name
Write-Host "InstanceIP: " $instanceIP

$query = 'ResourceRecordSets[?Name == ''' + $dns + ''']'
$r53Entries = (aws route53 list-resource-record-sets --hosted-zone-id $hostedZoneId --query $query | ConvertFrom-Json).Length

if ($r53Entries -eq 1)
{
    $changeBatch = '{ ""Comment"": ""Delete TeamServer DNS"", ""Changes"": [ { ""Action"": ""DELETE"", ""ResourceRecordSet"": { ""Name"": ""' + $dns + '"", ""Type"": ""A"", ""TTL"": 300, ""ResourceRecords"": [ { ""Value"": ""' + $instanceIP + '"" } ] } } ] }'
    Write-Host `n
    aws route53 change-resource-record-sets --hosted-zone-id $hostedZoneId --change-batch $changeBatch
    Write-Host "R53 entry deleted!"
}
else
{
    Write-Host "R53 does not exist!"
}