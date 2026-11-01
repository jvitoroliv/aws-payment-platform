$validFIs = "FINSERV,ClientBank"
$validEnvironments = "QA,UAT,PROD,DEMO"

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
