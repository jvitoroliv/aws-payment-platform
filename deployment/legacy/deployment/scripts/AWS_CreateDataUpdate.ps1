# Create DataUpdate container

Param(
	[string]$workdir
)

$packagedir = "${workdir}\DataUpdatePackage"
$artifactdir = "${workdir}\a"

If (Test-Path "${packagedir}") { Remove-Item -path "${packagedir}" -Recurse }
New-Item -Path "$workdir" -Name "DataUpdatePackage" -ItemType "directory"

Write-Host "Unpacking DataUpdate"
$dataupdateFilename = (Get-Childitem -path "${artifactdir}\DataUpdate" | Where { $_.Name -match "^CoreService.DataUpdate." } | Sort-Object | Select-Object -Last 1).Name
Expand-Archive -Path "${artifactdir}\DataUpdate\${dataupdateFilename}" -DestinationPath "${packagedir}\DataUpdate\"

Write-Host "Unpacking DeploymentTools"
$deploytoolsFilename = (Get-Childitem -path "${artifactdir}\General" | Where { $_.Name -match "^CoreService.DeploymentTools." } | Sort-Object | Select-Object -Last 1).Name
Expand-Archive -Path "${artifactdir}\General\${deploytoolsFilename}" -DestinationPath "${packagedir}\DataUpdate\DeploymentTools"

Write-Host "Unpacking Transforms"
$transformsFilename = (Get-Childitem -path "${artifactdir}\General" | Where { $_.Name -match "^CoreService.Transforms." } | Sort-Object | Select-Object -Last 1).Name
Expand-Archive -Path "${artifactdir}\General\${transformsFilename}" -DestinationPath "${packagedir}\DataUpdate\Transforms"

Write-Host "Unpacking DataBase"
$databaseFilename = (Get-Childitem -path "${artifactdir}\DataUpdate" | Where { $_.Name -match "^CoreService.DataBase." } | Sort-Object | Select-Object -Last 1).Name
Expand-Archive -Path "${artifactdir}\DataUpdate\${databaseFilename}" -DestinationPath "${packagedir}\DataBase\"

Write-Host ""
& "${artifactdir}\DeploymentScripts\AWS_GetHelpMappings.ps1" "${packagedir}\HelpMappings"

Copy-Item "${packagedir}\DataUpdate\dockerfile" "${packagedir}"

cd "${packagedir}"

Write-Host ""
Write-Host "Building DataUpdate docker image"
& Docker.exe build -t coreplatform_dataupdate .
