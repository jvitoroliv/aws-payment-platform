Param(
	[Parameter(Mandatory=$true)]
	[string]$env = "QA"	# DEV, QA, UAT, PROD
)

. C:\CorePlatform\SharedFunctions.ps1
Write-Msg "FTP server restore for env $env, step 1"

Write-Msg "Retrieving AD creds for AD join service user"
$adUser = "$($env.ToLower())/ad_service_account"
$adPassKey = "$($env.ToLower())/ad_service_password"
$adServiceuser = (Get-SECSecretValue -SecretId $adUser | Select-Object SecretString).SecretString
$adPass = (Get-SECSecretValue -SecretId $adPassKey | Select-Object SecretString).SecretString | ConvertTo-SecureString -asPlainText -Force
$credential = New-Object System.Management.Automation.PSCredential($adServiceuser,$adPass)

Write-Msg "Checking this computer is still joined to to the AD, it should not be"
$dnsDomain = "secure.finservglobal.example.com"
$computer = Get-ADComputer $env:computername -Credential $credential -Server $dnsDomain
if ($computer) {
	Write-Msg "Computer is still joined to AD, run AD cleanup, then rerun this script"
	return
}

Write-Msg "Disassociate this computer from the AD"
$password = $credential.GetNetworkCredential().Password
netdom remove $env:computername /Domain:$dnsDomain /UserD::$adServiceuser /PasswordD:$password /Force

Write-Msg "Setting next stage of Restore process in restore.txt"
"C:\CorePlatform\FTPServerRestoreStep2.ps1" | Out-File -FilePath c:\work\restore.txt

Write-Msg "Restarting computer"
Restart-Computer

Write-Msg "Computer is restarting now, watch instance screenshot to determine when restart is complete"

Write-Msg "Terminate this SSM session and when the restart is complete, start a new SSM session from AWS console, then run the step 2 script"

Write-Msg "FTP server restore, step 1 is complete."