Param(
    [string]$instanceId,
    [int]$maxtries = 120
)

Write-Host "Starting Instance $instanceId"
Start-EC2Instance -InstanceId $instanceId

$maxtries = 120
$tries = 0
while ($tries -lt $maxtries) {
  Start-Sleep -Seconds 5

  $tries++
  $state = Get-EC2InstanceStatus -InstanceId $instanceId -IncludeAllInstance $true
  Write-Host "Current state: " $state.InstanceState.Name.Value "/" $state.SystemStatus.Status
  if (($state.InstanceState.Name.Value -eq "running") -and ($state.SystemStatus.Status -eq "ok")) {
    Write-Host "Done!"
    break
  }
}