Param(
	[string]$SourceDir,								# folder to upload from
	[string]$bucketname = $env:ArtifactBucketName,	# to what S3 bucket
	[string]$keyprefix  = "CoreService_Artifacts",	#   in which folder
	[string]$region     = $env:AWSregion			#   in which AWS region
)

$bucketname = $bucketname.ToLower()
$region = $region.ToLower()

Write-Host "Uploading files to S3"
Get-ChildItem $SourceDir | % {
	$filename = $_.Name
	Write-Host "  $filename"
	Write-S3Object -BucketName "$bucketname" -Region "$region" -Key "$keyprefix\$filename" -File "$SourceDir\$filename"
}
