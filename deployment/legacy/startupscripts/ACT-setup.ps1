Param(
	[string]$type,
	[string]$username,
	[string]$password
)

# execute ACT script
$psscript = "C:\CoreService\StartupScripts\ACT-run.ps1"

$fi = $env:COREPLATFORM_FI
Write-Host "FI = $fi"
Write-Host "-------------------"

$scheduledTaskName = "ACT"

$scheduledTaskExists = Get-ScheduledTask | Where-Object {$_.TaskName -eq $scheduledTaskName}
if($scheduledTaskExists)
{
	Write-Host "Deleting scheduled task $scheduledTaskName"
	Unregister-ScheduledTask -TaskName $scheduledTaskName -Confirm:$false
}

# -- create scheduled task
$action = New-ScheduledTaskAction -Execute "Powershell" -Argument "-WindowStyle Hidden `"$psscript `'$type`' `'$fi`'"
$trigger = New-ScheduledTaskTrigger -Once -At (Get-Date) -RepetitionInterval (New-TimeSpan -Minutes 60) -RepetitionDuration (New-TimeSpan -Days (365 * 20))
$principal = New-ScheduledTaskPrincipal -UserID "$username" -LogonType ServiceAccount -RunLevel Highest
$settings = New-ScheduledTaskSettingsSet -MultipleInstances Parallel -Hidden -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable -RunOnlyIfNetworkAvailable

$task = New-ScheduledTask  -Action $action -Trigger $trigger -Settings $settings -Principal $principal
$task | Register-ScheduledTask -TaskName $scheduledTaskName -User $username -Password $password
Write-Host "Scheduled task $scheduledTaskName created"