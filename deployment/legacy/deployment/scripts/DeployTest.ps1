$ver = get-content "${env:System_DefaultWorkingDirectory}\CoreServiceArtifacts\CoreServiceVersion\_CoreServiceVersion.txt"

$OctoRelease = "$ver-${env:Channel}${env:Build_BuildNumber}"

write-host "Deploying DeployTest $OctoRelease"

& "c:\tools\appdeploy\appdeploy.exe" -p "DeployTest" -r "${OctoRelease}" -e -s "${env:OctopusUrl}" -a "${env:OctopusAPIkey}" -d "${env:Environment}" -t "${env:FI}"
