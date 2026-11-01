Param(
    [string]$instanceId,
    [int]$maxtries = 120
)

Write-Host "Stopping Instance $instanceId"
Stop-EC2Instance -InstanceId $instanceId

$maxtries = 120
$tries = 0
while ($tries -lt $maxtries) {
  Start-Sleep -Seconds 5

  $tries++
  $state = Get-EC2InstanceStatus -InstanceId $instanceId -IncludeAllInstance $true
  Write-Host "Current state: " $state.InstanceState.Name.Value
  if ($state.InstanceState.Name.Value -eq "stopped") {
    Write-Host "Done!"
    break
  }
}