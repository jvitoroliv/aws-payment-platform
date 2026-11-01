Param(
	[string]$DestDir
)

Write-Host "Downloading HelpMappings zip files"

$bucketname = $env:ArtifactBucketName
$region = $env:AWSregion
$keyprefix = "CoreService_Artifacts"

$s3objects = Get-S3Object -BucketName "$bucketname" -KeyPrefix "$keyprefix" -Region "$region"

# get helpmappings zip file from MAJOR and PROD branches

$Branches = ("MAJOR","PROD")

foreach($branch in $Branches) {
	Write-Host "Retreiving HelpMappings file for Branch $branch"

	$filter = "^(.)+/CoreService\.HelpMappings\.(.)+-${branch}(.)+\.zip$"
	$keys = $s3objects | Where-Object { $_.Key -match "$filter" }

	if ($keys) {
	
		$helpkey = $keys | Sort-Object -Property "Key" | Select-Object -Last 1
		$key = $helpkey.Key
		$localfile = "${DestDir}\HelpMappings-${branch}.zip"

		Write-Host "Downloading file $key"
		Copy-S3Object -BucketName "$bucketname" -Region "$region" -Key "$key" -LocalFile "$localfile"
	}
	else {
		Write-Warning "No HelpMappings file for Branch $branch found."
	}
}
