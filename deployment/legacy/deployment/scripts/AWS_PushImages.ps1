# push dataupdate image to ECR

Param(
	[string]$VersionPath,
	[string]$BuildInfoPath
)

$version = Get-Content "${VersionPath}\_CoreServiceVersion.txt"

$buildinfo = Get-Content "${BuildInfoPath}\BuildInfo.json" | Out-String | ConvertFrom-Json
$channel = $buildinfo.SourceBranch		# Major
$buildnumber = $buildinfo.BuildNumber	# 20210408.12345

write-host "tagging image ${channel}_${buildnumber}"
& docker.exe tag coreplatform_dataupdate:latest ${env:EcrUrl}/coreplatform_dataupdate:${channel}_${buildnumber}
write-host "tagging image ${version}-${channel}${buildnumber}"
& docker.exe tag coreplatform_dataupdate:latest ${env:EcrUrl}/coreplatform_dataupdate:${version}-${channel}${buildnumber}

write-host "pushing image"
& docker.exe push ${env:EcrUrl}/coreplatform_dataupdate:${channel}_${buildnumber}
& docker.exe push ${env:EcrUrl}/coreplatform_dataupdate:${version}-${channel}${buildnumber}
