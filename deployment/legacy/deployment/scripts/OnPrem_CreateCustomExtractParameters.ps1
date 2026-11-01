$validFIs = "AMEX,SAMPLE_FI,CENTRAL,COMMERCE,GENERIC,IBERIABANK,KEYBANK,PNC,REGIONS,SYNOVUS,USBANK,FINSERV"
$validEnvironments = "STAGING,DR STAGING,PRODUCTION,DEMO"

$path = ".\CustomExtractParameters"
if (!(Test-Path -path $path))
{
	New-Item $path -itemtype directory
}

$FI = ${env:FI}
if ($FI -eq 'CBKC') { $FI = 'Commerce' }
if ($FI -eq 'AKUSA') { $FI = 'Finservcorp' }

if (-not $validFIs.Split(",").Contains($FI.ToUpper())) {
	Write-Error "ERROR: Invalid FI ${FI}"
	Exit -1
}


$Environment = ${env:Environment}
if ($Environment -eq 'PAT') { $Environment = 'Staging' }
if ($Environment -eq 'UAT') { $Environment = 'DR Staging' }
if ($Environment -eq 'Prod') { $Environment = 'Production' }

if (-not $validEnvironments.Split(",").Contains($Environment.ToUpper())) {
	Write-Error "ERROR: Invalid Environment ${Environment}"
	Exit -1
}

$ExtractParams = @{
	FI="${FI}"
	Environment="${Environment}"
	TestName="${env:TestName}"
	ResultsFilename="${env:ResultsFilename}"
	DestinationEmail="${env:DestinationEmail}"
}

$ExtractParams | ConvertTo-Json | Out-File "${path}\CustomExtractParameters.json"
$ExtractParams | ConvertTo-Json | Out-File "${path}\ExtractSampleParameters.json" # remove after updating Octo project
