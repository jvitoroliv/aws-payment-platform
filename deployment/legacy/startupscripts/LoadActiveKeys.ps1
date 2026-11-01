# get ActiveKeys/<env> from Secrets Manager

$AKsecretName = "ActiveKeys/" + $env:COREPLATFORM_ENV  # ActiveKeys/Dev
Write-Host "Getting Secret $AKsecretName"

$AKsecret = Get-SECSecret -SecretId $AKsecretName
if (-not $AKsecret) {
	Write-Error "Secret $AKsecretName not found"
	return
}

$AKsecretDataJson = (Get-SECSecretValue -SecretId $AKsecretName).SecretString

#$AKsecretData = $AKsecretDataJson | ConvertFrom-Json -AsHashtable  # needs PS v6
$AKsecretData = @{}
(ConvertFrom-Json $AKsecretDataJson).psobject.properties | Foreach { $AKsecretData[$_.Name] = $_.Value }

# populate registry branches
$branchesToWrite = @(
	"hklm:\Software\CoreService\Encryption",
	"hklm:\Software\Wow6432Node\CoreService\Encryption"
    )

foreach ($branch in $branchesToWrite) 
{
	Write-Host "Branch: $branch"
    if (-not (Test-Path "${branch}")) {
        Write-Error "Branch $branch should already exist."
		return
    }
	
	Write-Host "Populating ActiveKeys"
	foreach ($FIname in $AKsecretData.Keys) # each FI, really FinservActiveKey, USBankActiveKey, etc.
	{
		$activekey = $AKsecretData[$FIname]
		Write-Host "  $FIname ActiveKey $activekey"
		Set-ItemProperty "${branch}" -Name "${FIname}" -Value "${activekey}"
	}
}


