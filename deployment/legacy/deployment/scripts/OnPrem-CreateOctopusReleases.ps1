# Create Octopus Releases

Param(
	[string]$BuildInfoPath,
	[string]$VersionPath,
	[string]$OctopusDir
)

$version = Get-Content "${VersionPath}\_CoreServiceVersion.txt"

$buildinfo = Get-Content "${BuildInfoPath}\BuildInfo.json" | Out-String | ConvertFrom-Json
$channel = $buildinfo.SourceBranch	# Major
$buildnumber = $buildinfo.BuildNumber	# 20210406.75993

$semver = "${version}-${channel}${buildnumber}"


Write-Host "Version = $version"
Write-Host "Channel = $channel"
Write-Host "BuildNumber = $buildnumber"
Write-Host ""
Write-Host "SemVer = $semver"

$OctopusUrl = $env:OctopusUrl
$OctopusAPIKey = $env:OctopusAPIKey

Write-Host "Creating CorePlatform Releases"
& "${OctopusDir}\Octo.exe" create-release --project="A) CorePlatform - Pre-Deploy" --channel="${Channel}" --version="${semver}" --server=$OctopusUrl --apiKey=$OctopusAPIKey --ignoreSslErrors
& "${OctopusDir}\Octo.exe" create-release --project="B) CorePlatform - Go Live" --channel="${Channel}" --version="${semver}" --server=$OctopusUrl --apiKey=$OctopusAPIKey --ignoreSslErrors
& "${OctopusDir}\Octo.exe" create-release --project="R) CorePlatform - Go Live Rolling" --channel="${Channel}" --version="${semver}" --server=$OctopusUrl --apiKey=$OctopusAPIKey --ignoreSslErrors
& "${OctopusDir}\Octo.exe" create-release --project="BG-A) CorePlatform - Pre-Deploy BlueGreen" --channel="${Channel}" --version="${semver}" --server=$OctopusUrl --apiKey=$OctopusAPIKey --ignoreSslErrors
& "${OctopusDir}\Octo.exe" create-release --project="BG-B) CorePlatform - Go Live BlueGreen" --channel="${Channel}" --version="${semver}" --server=$OctopusUrl --apiKey=$OctopusAPIKey --ignoreSslErrors
		
Write-Host "Creating CorePlatform Combined Releases"
& "${OctopusDir}\Octo.exe" create-release --project="A) CorePlatform Combined - Pre-Deploy" --channel="${Channel}" --version="${semver}" --server=$OctopusUrl --apiKey=$OctopusAPIKey --ignoreSslErrors
& "${OctopusDir}\Octo.exe" create-release --project="B) CorePlatform Combined - Go Live" --channel="${Channel}" --version="${semver}" --server=$OctopusUrl --apiKey=$OctopusAPIKey --ignoreSslErrors
& "${OctopusDir}\Octo.exe" create-release --project="R) CorePlatform Combined - Go Live Rolling" --channel="${Channel}" --version="${semver}" --server=$OctopusUrl --apiKey=$OctopusAPIKey --ignoreSslErrors
& "${OctopusDir}\Octo.exe" create-release --project="BG-A) CorePlatform Combined - Pre-Deploy BlueGreen" --channel="${Channel}" --version="${semver}" --server=$OctopusUrl --apiKey=$OctopusAPIKey --ignoreSslErrors
& "${OctopusDir}\Octo.exe" create-release --project="BG-B) CorePlatform Combined - Go Live BlueGreen" --channel="${Channel}" --version="${semver}" --server=$OctopusUrl --apiKey=$OctopusAPIKey --ignoreSslErrors

Write-Host "Creating TaskManager Releases"
& "${OctopusDir}\Octo.exe" create-release --project="A) TaskManagement - Pre-Deploy" --channel="${Channel}" --version="${semver}" --server=$OctopusUrl --apiKey=$OctopusAPIKey --ignoreSslErrors
& "${OctopusDir}\Octo.exe" create-release --project="B) TaskManagement - Go Live" --channel="${Channel}" --version="${semver}" --server=$OctopusUrl --apiKey=$OctopusAPIKey --ignoreSslErrors
& "${OctopusDir}\Octo.exe" create-release --project="R) TaskManagement - Deploy Selective Jobs" --channel="${Channel}" --version="${semver}" --server=$OctopusUrl --apiKey=$OctopusAPIKey --ignoreSslErrors
& "${OctopusDir}\Octo.exe" create-release --project="X) JobBinaries Versioned Deploy" --channel="${Channel}" --version="${semver}" --server=$OctopusUrl --apiKey=$OctopusAPIKey --ignoreSslErrors

Write-Host "Creating Application Connectivity Tester Release"
& "${OctopusDir}\Octo.exe" create-release --project="Application Connectivity Tester" --channel="${Channel}" --version="${semver}" --server=$OctopusUrl --apiKey=$OctopusAPIKey --ignoreSslErrors