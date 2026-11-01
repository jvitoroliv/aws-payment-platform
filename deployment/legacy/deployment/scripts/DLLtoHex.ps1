param (
	[string]$assemblypath,
	[string]$templatefile,
	[string]$outfile
)

# this requires PS 5.0, which isn't on servers yet
#$hex = Format-Hex -path $assemblypath     
#$assemblystring = ($hex.Bytes | foreach-object { $_.ToString("X2") }) -Join ""

# PS 4.0 compatible version
$bytes = [System.IO.File]::ReadAllBytes("$assemblypath")
$assemblystring = ($bytes | foreach-object { $_.ToString("X2") }) -Join ""

$result = ""
Get-Content $templatefile | ForEach-Object {
	$line = $_ -replace "{ASSEMBLYHEXBYTES}", $assemblystring
	$result += "$line`n"
}
$result | Set-Content $outfile
