Param(
	[string]$workdir,
	[string]$OctopusUrl,
	[string]$OctopusAPIkey
)

$artifactdir = "${workdir}\CustomExtractArtifacts"

$params = Get-Content "${artifactdir}\CustomExtractParameters\CustomExtractParameters.json" -raw | Convertfrom-Json

$fi = $params.FI
$deployto = $params.Environment

$OctoRelease = (Get-Content "${artifactdir}\OctoRelease\OctoRelease.txt").Trim()

& "${artifactdir}\OctoEXE\Octo.EXE" deploy-release --project "Custom Work" --server "${OctopusUrl}" --apiKey ${OctopusAPIkey} --channel "Custom" --version ${OctoRelease} --deployto ${deployto} --tenant ${fi} --waitfordeployment --ignoreSslErrors
