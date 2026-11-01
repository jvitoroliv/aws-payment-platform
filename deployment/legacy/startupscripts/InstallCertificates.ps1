# Import  certificate

$certfolder = "c:\temp\certificates"

$files = Get-ChildItem -Path "${certfolder}" -filter *.json

$files.ForEach(
{
$certinfo = Get-Content ${certfolder}\$_| ConvertFrom-Json


$CNName = $certinfo.CNName   


$regexCNname = "CN=" + $CNName.Replace("*","\*").Replace(".","\.").Replace("(","\(").Replace(")","\)")
$regexCNnameWithComma = $regexCNname + ","

$installpath = $certinfo.installpath

$certinstallpath = "cert:\LocalMachine\${installpath}"
#Write-Host $certinstallpath

$key = $certinfo.Key
$filename = $key.Split("/") | Select-Object -Last 1
#Write-Host $filename

$certfilepath = $certfolder + "\" + $filename
#Write-Host $certfilepath

if (-not (Test-Path $certfilepath)) {
    Write-Warning "Certificate file $certfilepath not found."
    return
}
$password = $certinfo.password
#Write-Host $password

#$certObj = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2
#$certObj.Import($certfilepath, "$password", "UserKeySet")
$certextension = (Get-Item $certfilepath).Extension.ToUpper()


# check if cert already installed
$certlist = Get-ChildItem -path $certinstallpath | Where-Object {($_.Subject -match $regexCNnameWithComma -or $_.Subject -eq $regexCNname)}
if ($certlist) {
    Write-Warning "Certificate $CNname already imported"
    return
}


# import cert

Write-Host "  Importing certificate $CNname"

if ($certextension -eq ".PFX") {
    # PFX cert

    # use alternative install method?
    $pfxalt = $certinfo.PFXalternative
    
    if ($pfxalt -ne "T" -and $pfxalt -ne "Y")
    {
        if ($password) {
            $passsecure = ConvertTo-SecureString -String $password -Force -AsPlainText
            Import-PfxCertificate -FilePath $certfilepath -CertStoreLocation "$certinstallpath" -password $passsecure # -whatif
        }
        else {
            Import-PfxCertificate -FilePath $certfilepath -CertStoreLocation "$certinstallpath" # -whatif # no password
        }
    }
    else
    {
        # PFX alternative
        if ($password) {
            CertUtil -f -p "${password}" -importpfx $certfilepath
        } 
        else {
            CertUtil -f -p '""' -importpfx $certfilepath   # no password
        }
    }
}
else {
    # normal cert
    Import-Certificate -FilePath $certfilepath -CertStoreLocation "$certinstallpath" # -whatif
}

# pause for install to complete cleanly
Start-Sleep -m 1000


# set permission to FI Domain User

Write-Host "  Assigning user permissions to certificate $CNName"

$certlist = Get-ChildItem -path $certinstallpath | Where-Object {($_.Subject -match $regexCNnameWithComma -or $_.Subject -eq $regexCNname)}
if (-not $certlist) {
    Write-Warning "Certificate $CNname not installed.  Cannot set rights."
    return
}

$cert = $certlist[0] 
$rsaFile = $cert.PrivateKey.CspKeyContainerInfo.UniqueKeyContainerName

if (-not $rsaFile) # no private key to which to assign permissions
{
    Write-Warning "Certificate does not possess private key.  Cannot set rights."
    return
}

$rsaFilePath = "C:\ProgramData\Microsoft\Crypto\RSA\MachineKeys\" + $rsaFile

$acl = Get-Acl -Path $rsaFilePath

$username = "Everyone"

Write-Host "Assigning user $username rights to certificate $CNName"
$permission = "$username","FullControl,Read","Allow"
$accessRule = new-object System.Security.AccessControl.FileSystemAccessRule $permission
$acl.AddAccessRule($accessRule)
Try {
    Set-Acl $rsaFilePath $acl
    # Write-Host "User $username given rights to certificate $CNname"
}
Catch {
    Write-Warning "Failed to assign user $username rights to certificate $CNname"
}
}
)

