Param(
	[string]$SourceDir,								# folder to upload from
	[string]$bucketname = $env:ArtifactBucketName,	# to what S3 bucket
	[string]$keyprefix  = "CoreService_Artifacts",	#   in which folder
	[string]$region     = $env:AWSregion,			#   in which AWS region
	[int]$maxfiles		= 3							# maximum number of each filename/branch to retain (default 3)
)

$bucketname = $bucketname.ToLower()
$region = $region.ToLower()

Write-Host "Uploading Artifacts to S3"

# first, just upload everything
Get-ChildItem $SourceDir | % {
	$filename = $_.Name
	Write-Host "  $filename"
	Write-S3Object -BucketName "$bucketname" -Region "$region" -Key "$keyprefix/$filename" -File "$SourceDir\$filename"
}

# clean-up
Write-Host ""
Write-Host "Cleaning up excess file on S3"

# get all the files on S3
Write-Host "  collecting S3 files list"
$S3files = Get-S3Object -BucketName "$bucketname" -Region "$region" -KeyPrefix "$keyprefix" |
	% { ($_.Key -Split '/')[1] }

# get collection of filename/branch for files in source folder
Write-Host "  parsing list of uploaded artifacts"
$files = Get-ChildItem $SourceDir | 
	% { $_.Name } |
	Select-String -Pattern '^(?<fileroot>[A-Za-z]+.[A-Za-z]+).\d+.\d+.\d+-(?<branch>\D+)\d+' | 
	% { $fileroot, $branch = $_.Matches[0].Groups['fileroot', 'branch'].Value; [PSCustomObject]@{ Fileroot = $fileroot; Branch = $branch } }

# for each fileroot/branch, get list of files currently on S3, and if number of files > limit, sort and delete oldest file(s) until only limit exist
$files | % { 
	$fileroot = $_.Fileroot;
	$branch = $_.Branch;
	$regex = "${fileroot}.\d+.\d+.\d+-${branch}\d+";
	
	$matching = $s3files -Match $regex
	$numfiles = $matching.Count
	
	Write-Host "  ${fileroot}/${branch} : ${numfiles} files"
	
	if ($numfiles -gt $maxfiles) {  # we got some deletin' to do
		Write-Host "    too many files, cleaning up"
		$matching | 
			Sort-Object |
			Select-Object -First ($numfiles - $maxfiles) |
			% { 
				$filename = $_; 
				Write-Host "    $filename";
				Remove-S3Object -Bucketname "$bucketname" -Region "$region" -Key "$keyprefix/$filename" -Force
			}
	}
}
