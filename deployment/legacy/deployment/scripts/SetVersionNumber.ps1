$ver = get-content _CoreServiceVersion.txt

Write-Host "##vso[task.setvariable variable=CoreServiceVersionNumber]$ver"
