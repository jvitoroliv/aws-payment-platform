param(
	[string] $BuildInfoPath,
	[string] $Environment,
	[string] $Fi,
	[string] $OctopusDir,
	[string] $VersionPath
	)

$version = Get-Content "${VersionPath}\_CoreServiceVersion.txt"

$buildinfo = Get-Content "${BuildInfoPath}\BuildInfo.json" | Out-String | ConvertFrom-Json
$channel = $buildinfo.SourceBranch	# Major
$buildnumber = $buildinfo.BuildNumber	# 20210406.75993

$semver = "${version}-${channel}${buildnumber}"
$fi = "${FI}"
$deployto = "${Environment}"

Write-Host "Version = $version"
Write-Host "Channel = $channel"
Write-Host "BuildNumber = $buildnumber"
Write-Host "FI = $fi"
Write-Host "SemVer = $semver"

$OctopusUrl = $env:OctopusUrl
$OctopusAPIKey = $env:OctopusAPIKey

Write-Host "Deploying Application Connectivity Tester Release"
& "${OctopusDir}\Octo.exe" deploy-release --project="Application Connectivity Tester" --channel="${Channel}" --version="${semver}" --deployto=$deployto --tenant=$fi --server=$OctopusUrl --apiKey=$OctopusAPIKey --waitfordeployment --ignoreSslErrors --deploymentTimeout=3600