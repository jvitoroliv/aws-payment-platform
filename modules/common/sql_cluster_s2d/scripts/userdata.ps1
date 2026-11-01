# User Data 
# ------------------------------------
# Joins Active Directory Domain
#
# Terraform Inputs:
#   join_domain_ssm_document: The name of the SSM Document to use for auto-joining the AD domain.
#
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
New-Item -ItemType directory -Path C:\work -Force
Start-Transcript -Path C:\work\userdata.log -Append
Import-Module AWSPowerShell

# Metadata
# ------------------------------------
Set-Variable -name az -value (Invoke-RestMethod -Method Get -Uri http://169.254.169.254/latest/meta-data/placement/availability-zone)
Set-Variable -name instance_id -value (Invoke-RestMethod -uri http://169.254.169.254/latest/meta-data/instance-id)

# Misc
# ------------------------------------
# Ensure NuGet & other required 3rd-party modules are installed:
# Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force
# Install-Module -Name PowerShellGet -Force

# Bootstrapping
# ------------------------------------
# Start the SSM Agent just in case it's stopped:
Start-Service -Name "AmazonSSMAgent"

# --------------
# Environment specific values
$hostname = "${hostname}"
$dnsDomain = "${dns_domain}"
$adUser    = "${coreplatform_env}/ad_service_account"
$adPassKey  = "${coreplatform_env}/ad_service_password"
$oupath  = "${oupath}"

# --------------
If ($env:computername -ne $hostname) {
    Write-Log-Message "Computer hostname $env:computername does not match expected hostname $hostname"

    Write-Log-Message "Reenable Userdata to run on next reboot"
    C:\ProgramData\Amazon\EC2-Windows\Launch\Scripts\InitializeInstance.ps1 -Schedule

    Rename-Computer -NewName $hostname -Confirm:$false -Force

    Write-Log-Message "Stopping transcript, forcing restart"
    Stop-Transcript

    Restart-Computer

} ElseIf ((Get-WmiObject win32_computersystem).partofdomain) {
    Write-Log-Message "Computer joined in AD"
    
    Write-Output "Executing SSM Automation document..."
    Start-SSMAutomationExecution -DocumentName "${ssm_config}" 

    Stop-Transcript

} Else {
    Write-Log-Message "Computer NOT joined in AD"

    Write-Log-Message "Reenable Userdata to run on next reboot"
    C:\ProgramData\Amazon\EC2-Windows\Launch\Scripts\InitializeInstance.ps1 -Schedule

    Write-Log-Message "Install RSAT-AD-PowerShell"
    Install-WindowsFeature -Name RSAT-AD-PowerShell

    # set up the FI eventlog source, no need to set this for shared aka non-FI instances
    if (-not ([string]::IsNullOrWhiteSpace("${coreplatform_fi}"))) {
        Write-Log-Message "Set computer event source"
        [system.diagnostics.EventLog]::CreateEventSource("${coreplatform_fi}", "Application")
    }

    Write-Log-Message "Get AD domain admin creds"
    $adServiceuser = (Get-SECSecretValue -SecretId $adUser | Select-Object SecretString).SecretString
    $adPass = (Get-SECSecretValue -SecretId $adPassKey | Select-Object SecretString).SecretString | ConvertTo-SecureString -asPlainText -Force
    $credential = New-Object System.Management.Automation.PSCredential($adServiceuser,$adPass)


    # Add computer to active directory
    Write-Log-Message "Add computer to AD (oupath: $oupath)"
    Add-Computer -ComputerName $hostname -DomainName $dnsDomain -Credential $credential -OUPath $oupath -Force
    
    Write-Log-Message "Stopping transcript, forcing restart"
    Stop-Transcript

    Restart-Computer
}
</powershell>
