Param(
	[string]$key,
    [string]$value
)

Write-Host "Setting EC2 Tag Key=$key Value=$value"

Set-Variable -name instanceId -value (Invoke-RestMethod -uri http://169.254.169.254/latest/meta-data/instance-id)
New-EC2Tag -Resource $instanceId -Tag @{Key=$key;Value=$value} -Force
