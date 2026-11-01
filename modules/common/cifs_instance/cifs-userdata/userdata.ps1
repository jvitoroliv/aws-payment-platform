# User Data
# ------------------------------------
# Joins Domain and Configures CIFS Shares
#
# Terraform Inputs:
#   ssm_document: The name of the SSM Document to use for auto-join domain
#   shares: A string of semi-colon delimited values representing "share-name = permission-group"
#
<powershell>
Set-ExecutionPolicy unrestricted -Scope CurrentUser -Force
Set-TimeZone "Eastern Standard Time"
New-Item -ItemType directory -Path C:\TEMP -Force
start-transcript -Path C:\TEMP\userdata.log -Append
Import-Module AWSPowerShell


# Metadata
# ------------------------------------
Set-Variable -name az -value (Invoke-RestMethod -Method Get -Uri http://169.254.169.254/latest/meta-data/placement/availability-zone)
Set-Variable -name instance_id -value (Invoke-RestMethod -uri http://169.254.169.254/latest/meta-data/instance-id)
$region = $az.Substring(0, $az.length-1)


# Services
# ------------------------------------
Start-Service -Name "AmazonSSMAgent"


# Prep CIFS Script
# ------------------------------------
$PrepCifs=@"
## Define shares to create, format is (Sharename = 'domain\rwgroupname'; )
#
`$CreateShares = @{ ${shares} }

## Prepare data drive for use
#
Get-Disk |
Where partitionstyle -eq 'raw' |
Initialize-Disk -PartitionStyle GPT -PassThru |
New-Partition -DriveLetter D -UseMaximumSize |
Format-Volume -FileSystem NTFS -NewFileSystemLabel "datavol" -Confirm:`$false

## Create shares
#
`$CreateShares.Keys | %%{

  New-Item -ItemType directory -Path D:\`$_
  # disabling permissions until customer provides that information
  New-SmbShare -Name `$_ -Path "D:\`$_" -FullAccess `$CreateShares.Item(`$_)
}
"@

if ((gwmi win32_computersystem).partofdomain) {
  # Domain joined already...
  # Run CIFS Prep script

  New-Item -ItemType directory -Path C:\TEMP -Force
  start-transcript -Path C:\TEMP\userdata.log -Append
  $PrepCifs| Out-File -FilePath C:\TEMP\PrepCifs.ps1 -Encoding ASCII
  if (! (Test-Path D:\ )) {
    Invoke-Command -Computer localhost -FilePath c:\temp\PrepCifs.ps1
  }

} else {
  # Not domain joined....
  # Re-enable userdata, join the domain, and restart

  Write-Output "Instance not on the domain, reenabling Userdata run on next reboot, and adding to domain."
  C:\ProgramData\Amazon\EC2-Windows\Launch\Scripts\InitializeInstance.ps1 -Schedule

  $svc = Get-Service AmazonSSMAgent
  $svc.WaitForStatus('Running')

  Rename-Computer ${hostname} -Force

  Set-DefaultAWSRegion -Region $region
  New-SSMAssociation -InstanceId $instance_id -Name "${ssm_document}"

  Write-Output "Stopping transcript, and rebooting host"
  Stop-Transcript

  Start-Sleep -Seconds 60  # to avoid any race conditions
}

</powershell>
