Param(
	[string]$ENV,
	[string]$COREPLATFORM_BRANCH,
	[string]$workdir,
	[string]$TRANSFORM_FLAGS
)

$dbdeploy = "${workdir}\DBDeploy"
$encartifactdir = "${workdir}\CoreServiceAWS"

If (Test-Path "${dbdeploy}") { Remove-Item -path "${dbdeploy}" -Recurse }
New-Item -Path "$workdir" -Name "DataUpdate" -ItemType "directory"

Write-Host "Unpacking DataUpdate"
$dataupdateFilename = (Get-Childitem -path "${encartifactdir}\DataUpdate" | Where { $_.Name -match "^CoreService.DataUpdate." } | Sort-Object | Select-Object -Last 1).Name
Expand-Archive -Path "${encartifactdir}\DataUpdate\${dataupdateFilename}" -DestinationPath "${dbdeploy}\DataUpdate\"

Write-Host "Unpacking DeploymentTools"
$deploytoolsFilename = (Get-Childitem -path "${encartifactdir}\General" | Where { $_.Name -match "^CoreService.DeploymentTools." } | Sort-Object | Select-Object -Last 1).Name
Expand-Archive -Path "${encartifactdir}\General\${deploytoolsFilename}" -DestinationPath "${dbdeploy}\DataUpdate\DeploymentTools"

Write-Host "Unpacking Transforms"
$transformsFilename = (Get-Childitem -path "${encartifactdir}\General" | Where { $_.Name -match "^CoreService.Transforms." } | Sort-Object | Select-Object -Last 1).Name
Expand-Archive -Path "${encartifactdir}\General\${transformsFilename}" -DestinationPath "${dbdeploy}\DataUpdate\Transforms"

Write-Host "Unpacking DataBase"
$databaseFilename = (Get-Childitem -path "${encartifactdir}\DataUpdate" | Where { $_.Name -match "^CoreService.DataBase." } | Sort-Object | Select-Object -Last 1).Name
Expand-Archive -Path "${encartifactdir}\DataUpdate\${databaseFilename}" -DestinationPath "${dbdeploy}\DataBase\"

Push-Location ${dbdeploy}\DataUpdate

& .\TaskDataUpdate.ps1 ${ENV} ${COREPLATFORM_BRANCH} "${TRANSFORM_FLAGS}"

Pop-Location
