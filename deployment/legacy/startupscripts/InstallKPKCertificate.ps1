# Import KPK certificate

$certfolder = "c:\CorePlatform\Certificates"

Write-Host "Importing certificate from folder $certfolder"

$infofilepath = "${certfolder}\certinfo.json"
if (!(Test-Path $infofilepath))
{
	Write-Error "certinfo.json not found in specified path."
	exit
}

$certinfo = get-content $infofilepath | ConvertFrom-Json

$CNName = $certinfo.CNName   # will be AOC-KPK-xxxx

$regexCNname = "CN=" + $CNName.Replace("*","\*").Replace(".","\.").Replace("(","\(").Replace(")","\)")

$installpath = $certinfo.installpath
$certinstallpath = "cert:\LocalMachine\${installpath}"

$key = $certinfo.Key
$filename = $key.Split("/") | Select-Object -Last 1
$certfilepath = "${certfolder}\${filename}"

$password = $certinfo.password

$certObj = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2
$certObj.Import($certfilepath, "$password", "UserKeySet")


# install cert

Write-Host "Certificate $CNname will be installed"

CertUtil -f -p "${password}" -importpfx $certfilepath

    
# pause for install to complete cleanly
Start-Sleep -m 1000

# cleanup
Remove-Item $certfilepath
Remove-Item $infofilepath


# set permission to FI Domain User

Write-Host "Assigning user permissions to certificate $CNName"

$certlist = Get-ChildItem -path $certinstallpath | Where-Object { $_.Subject -eq $regexCNname }
if (-not $certlist) {
	Write-Error "Certificate $CNname not installed.  Cannot set rights."
    exit
}
 
$cert = $certlist[0] 
$rsaFile = $cert.PrivateKey.CspKeyContainerInfo.UniqueKeyContainerName
    
if (-not $rsaFile) # no private key to which to assign permissions
{
	Write-Error "Certificate does not possess private key.  Cannot set rights."
	exit
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
	Write-Error "Failed to assign user $username rights to certificate $CNname"
	exit
}
