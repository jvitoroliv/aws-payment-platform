Param(
    [string]$instanceId,
    [string]$newInstanceType
)

$instanceType = (Get-EC2InstanceAttribute -InstanceId $instanceId -Attribute instanceType).InstanceType
Write-Host "Current InstanceType: " $instanceType

if ($instanceType -ne "$newInstanceType") {
  Write-Host "Updating InstanceType to: " $newInstanceType
  Edit-EC2InstanceAttribute -InstanceId $instanceId -InstanceType "$newInstanceType"
}

Write-Host "Done!"