Param(
    [string]$environment,
    [string]$instances
)

$environment = $environment.ToLower()

Write-Host "Retrieving AD creds for AD join service user"
$adUser = "$($environment.ToLower())/ad_service_account"
$adPassKey = "$($environment.ToLower())/ad_service_password"
$adServiceuser = (Get-SECSecretValue -SecretId $adUser | Select-Object SecretString).SecretString
$adPass = (Get-SECSecretValue -SecretId $adPassKey | Select-Object SecretString).SecretString | ConvertTo-SecureString -asPlainText -Force
$credential = New-Object System.Management.Automation.PSCredential($adServiceuser,$adPass)

Write-Host "Checking instances in AD"
$dnsDomain = "secure.finservglobal.example.com"

foreach($instance in $instances.Split(',')) {
    try {
        $computer = Get-ADComputer $instance -Credential $credential -Server $dnsDomain
        if ($computer) {
	        Write-Host "$instance is still joined to AD, removing"
            Remove-ADComputer -Identity $instance -confirm:$false -Credential $credential -Server $dnsDomain
        }
    }
    catch {
        Write-Host "$instance not found"
    }
}

Write-Host "Done!"
