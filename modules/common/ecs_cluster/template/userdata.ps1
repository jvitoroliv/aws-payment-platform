<powershell>

function Write-Log-Message
{
    [CmdletBinding()]
    Param
    (
        [Parameter(Mandatory=$true, Position=0)]
        [string]$LogMessage
    )

    Write-Output ("{0} - {1}" -f (Get-Date), $LogMessage)
}

Set-ExecutionPolicy unrestricted -Scope CurrentUser -Force
Set-TimeZone "Eastern Standard Time"
New-Item -ItemType directory -Path C:\TEMP -Force
Start-Transcript -Path C:\TEMP\userdata.log -Append
Import-Module AWSPowerShell
Import-Module ECSTools

# Metadata
# ------------------------------------
Set-Variable -name az -value (Invoke-RestMethod -Method Get -Uri http://169.254.169.254/latest/meta-data/placement/availability-zone)
Set-Variable -name instance_id -value (Invoke-RestMethod -uri http://169.254.169.254/latest/meta-data/instance-id)
$region = $az.Substring(0, $az.length-1)

# Services
# ------------------------------------
Start-Service -Name "AmazonSSMAgent"

# AD join
# ------------------------------------
if ((Get-WmiObject win32_computersystem).partofdomain) {
    # Domain joined already...

    Write-Log-Message "Computer joined in AD, starting docker/ECSAgent"
    
	Write-Log-Message "Restarting docker"
	Restart-Service Docker

	# Enable IAM roles for tasks
	# https://docs.aws.amazon.com/AmazonECS/latest/developerguide/windows_task_IAM_roles.html
	Write-Log-Message "Initialize-ECSAgent"
	Initialize-ECSAgent -Cluster ${cluster_name} -EnableTaskIAMRole -LoggingDrivers '["json-file","awslogs"]'
	
    Stop-Transcript

} else {
    # Not domain joined....
    # Re-enable userdata, join the domain, and restart

	# Each FI has their own event source
	[system.diagnostics.EventLog]::CreateEventSource("${coreplatform_fi}", "Application")

    Write-Log-Message "Instance not on the domain, reenabling Userdata run on next reboot, and adding to domain."
    C:\ProgramData\Amazon\EC2-Windows\Launch\Scripts\InitializeInstance.ps1 -Schedule

    Write-Log-Message "Waiting for AmazonSSMAgent"
    $svc = Get-Service AmazonSSMAgent
    $svc.WaitForStatus('Running')

    # --------------
	Write-Log-Message "Renaming computer"
	$shortid = $instance_id.substring(2,8)
	Rename-Computer -NewName "${hostname}-$shortid" -Force	

	Write-Log-Message "Setting SSM association"
	Set-DefaultAWSRegion -Region $region
	New-SSMAssociation -InstanceId $instance_id -Name "${ssm_document}"

	Write-Log-Message "Start sleep"
	Start-Sleep -Seconds 60  # to avoid any race conditions
	Write-Log-Message "Sleep complete"

	Write-Log-Message "Stopping transcript, forcing restart"
	Stop-Transcript

	# Restart-Computer
}    
</powershell>
