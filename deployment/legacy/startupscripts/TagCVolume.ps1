$instanceId = (Invoke-RestMethod -uri http://169.254.169.254/latest/meta-data/instance-id)

$instanceName = Get-EC2Tag -Filter @{Name="resource-id";Values=$instanceId} | Where-Object -Property Key -EQ "Name" | Select-Object -ExpandProperty Value

# assume C drive is always disk 0
$volumeid = ((Get-Disk | where-object {$_.Number -eq 0 }).SerialNumber).Substring(0,20).Replace("vol","vol-")

$volumeNameTag = Get-EC2Tag -Filter @(@{ name = 'tag:Name'; values = "*" }; @{ name = "resource-type"; values = "volume" }; @{ name = "resource-id"; values = $volumeid }) | Select-Object -ExpandProperty Value

# set the tag if it isn't already set
if (-not $volumeNameTag)
{
	New-EC2Tag -Resource $volumeid -Tag @{Key = "Name"; Value = "$instanceName-root" } -Force
}