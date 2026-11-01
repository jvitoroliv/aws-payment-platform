param (
	[string]$OctoProject
)

$ver = get-content "${env:System_DefaultWorkingDirectory}\CoreServiceArtifacts\CoreServiceVersion\_CoreServiceVersion.txt"
$roleFilePath = "${env:System_DefaultWorkingDirectory}\CoreServiceArtifacts\Roles\_Roles.lst"

$OctoRelease = "$ver-${env:Channel}${env:Build_BuildNumber}"

write-host "CoreService PreDeploy $OctoRelease"

& "c:\tools\appdeploy\appdeploy.exe" -p "${OctoProject}" -r "${OctoRelease}" -s "${env:OctopusUrl}" -a "${env:OctopusAPIkey}" -d "${env:Environment}" -t "${env:FI}" -f "${roleFilePath}"
