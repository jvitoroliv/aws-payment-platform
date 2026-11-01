$ver = get-content "${env:System_DefaultWorkingDirectory}\CoreServiceArtifacts\CoreServiceVersion\_CoreServiceVersion.txt"

& "c:\Tools\ADO-Tools\ADOReleaseTag.exe" -a "${env:System_AccessToken}" -c ${env:Build_SourceVersion} -t "${ver}-${env:EnvShortName}"
