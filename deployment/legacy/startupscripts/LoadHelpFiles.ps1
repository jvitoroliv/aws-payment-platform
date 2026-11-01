# load help files
$fi = $env:COREPLATFORM_FI
$env = $env:COREPLATFORM_ENV

$branch = "PROD"
if (("DEV","QA","MAJOR","UAT") -contains $env) { $branch = "MAJOR" }

$localpath = Get-Location
$helpfilename = "${localpath}\HelpFiles\${fi}-${branch}.zip"
$helppath = "${localpath}\Help\"

Add-Type -AssemblyName System.IO.Compression.FileSystem
[System.IO.Compression.ZipFile]::ExtractToDirectory($helpfilename, $helppath)
