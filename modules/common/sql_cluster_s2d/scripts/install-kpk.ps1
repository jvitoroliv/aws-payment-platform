[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]
    $DomainAdminUser,

    [Parameter(Mandatory = $true)]
    [string]
    $DomainAdminPasswordARN,

    [Parameter(Mandatory = $true)]
    [string]
    $NetBiosDomainName,

    [Parameter(Mandatory = $true)]
    [string]
    $SQLSvcAcctCredentialsARN,

    [Parameter(Mandatory = $true)]
    [string]
    $ArtifactsBucket,

    [Parameter(Mandatory = $true)]
    [string]
    $Environment
)

try {
    Start-Transcript -Path C:\SQLClusterDSCConfig\log\InstallKPK.ps1.txt -Append

    $ErrorActionPreference = "Stop"


    $DomainAdminUser = $NetBiosDomainName + '\' + $DomainAdminUser
    # TODO: possibly unnecessary
    #Write-Host "Getting AD Admin creds from Secrets Manager."
    #$DomainAdminPassword = (Get-SECSecretValue -SecretId $DomainAdminPasswordARN).SecretString
    #$ADCredentials = (New-Object PSCredential($DomainAdminUser, (ConvertTo-SecureString $DomainAdminPassword -AsPlainText -Force)))

    Write-Host "Getting SQL service account info from Secrets Manager."
    $SQLSvcAcctCredsFromSecretsMgr = ConvertFrom-JSON -InputObject (Get-SECSecretValue -SecretId $SQLSvcAcctCredentialsARN).SecretString
    $SQLSvcAcctUser = $SQLSvcAcctCredsFromSecretsMgr.Userid



    # Download KPK install scripts
    Write-Host "Downloading KPK scripts."
    $s3bucket = "$ArtifactsBucket"
    $fileName = "CoreService.Encryption.TestOnly.zip"
    $key = "CoreService_Artifacts/$filename"
    $outfile = "C:\TEMP\$fileName"

    # Download: If local file does not exist
    # OR (if local file exists AND the S3 version is newer)
    $S3LastUpdated = (Get-S3Object -BucketName $s3bucket -Key $key).LastModified
    If (  (-Not (Test-Path $outfile -PathType Leaf) ) -or ( ($S3LastUpdated -gt (Get-Item $outfile).LastWriteTime) -and (Test-Path $outfile -PathType Leaf) ) ) {
      Read-S3Object -BucketName $s3bucket -Key $key -File $outfile -Verbose
    }
    Write-Host "Download complete."

    Write-Host "Unzipping KPK scripts."
    $unzipPath = "C:\TEMP\Encryption"
    Add-Type -AssemblyName System.IO.Compression.FileSystem
    function Unzip
    {
        param([string]$zipfile, [string]$outpath)
        [System.IO.Compression.ZipFile]::ExtractToDirectory($zipfile, $outpath)
    }
    Unzip $outfile $unzipPath
    Write-Host "Unzip complete."

    Write-Host "Running KPK scripts."
    $environment = "TEST"
    $usernames = "$DomainAdminUser,$SQLSvcAcctUser" # TODO: update this list
    Set-Location $unzipPath
    .\InstallCertificateAndRegistry.ps1 $environment $usernames

    Write-Host "Run complete."




}
catch {
    Write-Verbose "$($_.exception.message)@ $(Get-Date)"
    throw $_
}
