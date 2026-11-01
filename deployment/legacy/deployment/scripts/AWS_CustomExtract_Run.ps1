Param(
	[string]$workdir
)

$rundir = "${workdir}\CustExt"
$CEartifactdir = "${workdir}\CustomExtractArtifacts\CustomExtract"

# get filesToZip

If (Test-Path "${rundir}") { Remove-Item -path "${rundir}" -Recurse }
New-Item -Path "$workdir" -Name "CustExt" -ItemType "directory"

Write-Host "Unpacking DeploymentTools"
$deploytoolsFilename = (Get-Childitem -path "${CEartifactdir}" | Where { $_.Name -match "^CoreService.DeploymentTools." } | Sort-Object | Select-Object -Last 1).Name
Expand-Archive -Path "${CEartifactdir}\${deploytoolsFilename}" -DestinationPath "${rundir}\DeploymentTools"

Write-Host "Unpacking Transforms"
$transformsFilename = (Get-Childitem -path "${CEartifactdir}" | Where { $_.Name -match "^CoreService.Transforms." } | Sort-Object | Select-Object -Last 1).Name
Expand-Archive -Path "${CEartifactdir}\${transformsFilename}" -DestinationPath "${rundir}\Transforms"

Write-Host "Unpacking Custom Extract"
$custextFilename = (Get-Childitem -path "${CEartifactdir}" | Where { $_.Name -match "^TaskManagement.CustomExtract." } | Sort-Object | Select-Object -Last 1).Name
Expand-Archive -Path "${CEartifactdir}\${custextFilename}" -DestinationPath "${rundir}"


# Run the Extract

Push-Location $rundir

# get region
Set-Variable -name AWSregion -value (Invoke-RestMethod -Method Get -Uri http://169.254.169.254/latest/meta-data/placement/region)
Write-Host "Region = $AWSregion"
Write-Host

$buildinfo = Get-Content .\BuildInfo.json -raw | ConvertFrom-Json
$buildnumber = $buildinfo.BuildNumber
$branch = $buildinfo.SourceBranch
Write-Host "BuildNumber = $buildnumber"
Write-Host "Branch = $branch"
Write-Host

$params = Get-Content .\CustomExtractParameters.json -raw | ConvertFrom-Json
$fi = $params.FI
$env = $params.Environment
$testname = $params.TestName
$resultsfilename = $params.ResultsFilename
$destinationemail = $params.DestinationEmail
Write-Host "FI = $fi"
Write-Host "Environment = $env"
Write-Host "TestName = $testname"
Write-Host "ResultsFilename = $resultsfilename"
#Write-Host "DestinationEmail = $destinationemail"
Write-Host

# transform
Write-Host "Transforming ExtractJobs.Test config"
#xform ExtractJobs.Test.dll.config --> global, app.config_ExtractJobs, cleanup
& ".\DeploymentTools\XmlTransformer.exe" -s "ExtractJobs.Test.dll.config" -r "ExtractJobs.Test.dll.config" -t ".\Transforms\Global.aocxdt;.\app.config_ExtractJobsTest.aocxdt;.\Transforms\Cleanup.aocxdt" -f $fi -e $env -g AWS -m $env:COMPUTERNAME -p AwsSecretsManager --AwsRegion $AWSregion

Write-Host "Running the Extract $testname"
& "c:\Program Files (x86)\NUnit 2.7.1\bin\nunit-console.exe" /run:${testname} ExtractJobs.Test.dll /err:StdErr.txt

Write-Host "Collecting the file(s) and zipping"
$resultsfolder = $env:TEMP

$filesToZip = "${resultsfolder}\${resultsfilename}", ".\ExtractJobsTest.log", ".\StdErr.txt"
foreach($file in $filesToZip) {
	if (Test-Path "${file}") {
		Compress-Archive -Update -Path "${file}" -DestinationPath .\Results.zip
	}
	else {
		Write-Warning "File ${file} not found."
	}
}

#Write-Host "Emailing results to $destinationemail"
#
## extract smtpServer from config appSettings
#$appSetting = Select-Xml -Path .\ExtractJobs.Test.dll.config -XPath 'configuration/appSettings/add' | Where { $_.Node.Key -eq "smtpServer" } | Select-Object -Last 1
#$smtpServer = $appSetting.Node.value
#Write-Host "smtpServer = $smtpServer"
#
#$to = $destinationemail.Split(',')
#Send-MailMessage -SmtpServer "$smtpServer" -From "CustomWork@platform.example.com" -To $to -Subject "${branch} Results" -Body "${branch} Results attached" -Attachments "Results.zip"

Pop-Location
