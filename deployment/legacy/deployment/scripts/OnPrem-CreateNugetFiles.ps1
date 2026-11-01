# Create nuget components

Param(
	[string]$sourcefolder,
	[string]$destfolder,
	[string]$componentlist,
	[string]$nugetfolder
)

Add-Type -AssemblyName System.IO.Compression.FileSystem
# Expand-Archive doesn't work on tfs-build02, so use this

If (-not (Test-Path "${destfolder}")) {
	New-Item -Path "${destfolder}" -Name "DataUpdatecomponent" -ItemType "directory"
}

$workfolder = "${destfolder}\work"
if (Test-Path -Path "$workfolder") {
	Remove-Item -path "${workfolder}" -Recurse
}

foreach($component in $componentlist.Split(',')) {

	if ($component -match ":") {
		$parts = $component.Split(":")
		$rootfilename = $parts[0]
		$nuspecfilename = $parts[1]+".nuspec"
	}
	else {
		$rootfilename = $component
		$nuspecfilename = ""
	}

	Write-Host "Unpacking ${zipfilename}"
	$filter = "^${rootfilename}."
	$files = Get-Childitem -path "${sourcefolder}" | Where { $_.Name -match "${filter}" }
	if (-not $files) {
		Write-Host "  ${rootfilename} not selected.  skipping"
        Continue
	}
	$filename = ($files | Select-Object -Last 1).Name
	Write-Host "  Unpacking ${filename}"

	New-Item -Path "$destfolder" -Name "work" -ItemType "directory"
	#Expand-Archive -Path "${sourcefolder}\${filename}" -DestinationPath "${workfolder}\"
	[System.IO.Compression.ZipFile]::ExtractToDirectory("${sourcefolder}\${filename}", "${workfolder}\")	

	$version = $filename.Split(".")[2..5] -Join '.'

	Write-Host "  Nugetting ${component}"

	Push-Location "${workfolder}"
		if (-not $nuspecfilename) {
			$nuspecfiles = Get-Childitem | Where { $_.Name -match ".nuspec$" } | Sort-Object | Select-Object -Last 1
			if (-not $nuspecfiles) {
				Write-Host "  No nuspec files specified or found."
			}
			else {
				# hopefully only one, but if >1 take last one
				$nuspecfilename = ($nuspecfiles | Select-Object -Last 1).Name
			}
		}
		
		if (-not (Test-Path $nuspecfilename)) {
			Write-Host "  Nuspec file $nuspecfilename not found."
		}
		else {
		    & "${nugetfolder}\NuGet.exe" pack "${nuspecfilename}" -OutputDirectory "${destfolder}" -Version "${version}" -NoPackageAnalysis
		}
	Pop-Location
	
	Remove-Item -path "${workfolder}" -Recurse
}
