Param(
	[Parameter(Mandatory=$true)]
	[string]$env = "QA"	# DEV, QA, UAT, PROD, QAT (when QA is using the new OU path this is the env)
)

. C:\CorePlatform\SharedFunctions.ps1
Write-Msg "FTP server restore for env $env, step 2"

Write-Msg "Retrieving AD creds for AD join service user"
$adUser = "$($env.ToLower())/ad_service_account"
$adPassKey = "$($env.ToLower())/ad_service_password"
$adServiceuser = (Get-SECSecretValue -SecretId $adUser | Select-Object SecretString).SecretString
$adPass = (Get-SECSecretValue -SecretId $adPassKey | Select-Object SecretString).SecretString | ConvertTo-SecureString -asPlainText -Force
$credential = New-Object System.Management.Automation.PSCredential($adServiceuser,$adPass)

Write-Msg "Add computer to AD"
$dnsDomain = "secure.finservglobal.example.com"

# the standard Secure AD OU path but override below if needed
$oupath = "OU=FINSERV,OU=$env,OU=WEB,OU=ENC,OU=Servers,OU=FINSERVGlobal,DC=SECURE,DC=FINSERVGLOBAL,DC=COM"
if ($env -eq "DEV") {
	# the dev env is using managed AD, not Secure AD
	$oupath = "OU=Computers,OU=ad,DC=ad,DC=dev,DC=encawsad,DC=test"
}
Write-Msg "oupath: $oupath"

Add-Computer -ComputerName $env:computername -DomainName $dnsDomain -Credential $credential -OUPath $oupath -Force -Options JoinWithNewName,AccountCreate

Write-Msg "Ending Restore Process stages"
Set-Variable -name instance_id -value (Invoke-RestMethod -uri http://169.254.169.254/latest/meta-data/instance-id)
$instance = Get-EC2Instance -InstanceId $instance_id
foreach ($tag in $instance.instances[0].tags) {
    if ($tag.key -ceq "Restoring") {
        Write-Msg "Removing Restoring Tag"
        Remove-EC2Tag -Resource $instance_id -Tag $tag -Force
    }
}
Write-Msg "Removing restore.txt file"
Remove-Item c:\work\restore.txt

Write-Msg "Restarting computer"
Restart-Computer

Write-Msg "Computer is restarting now, watch instance screenshot to determine when restart is complete"

Write-Msg "FTP server restore, step 2 is complete."