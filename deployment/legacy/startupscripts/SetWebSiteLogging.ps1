Param(
	[string]$sitetype
)

Import-Module WebAdministration

$root = "c:\Work"
$folder = "${env:COREPLATFORM_ENV}\${env:COREPLATFORM_FI}\${env:COMPUTERNAME}"
$sitefolder = "${root}\${folder}"
$siteLogFolder = "${root}\${folder}\${sitetype}"

$siteName = "Default Web Site"
$website = Get-Website | Where { $_.Name -eq $siteName }
$website.logFile.directory = "$siteLogFolder"
$website.logFile.logFormat = "W3C"
$website.logFile.logExtFileFlags = "Date,Time,ClientIP,UserName,SiteName,ComputerName,ServerIP,ServerPort,Method,UriStem,UriQuery,HttpStatus,HttpSubStatus,Win32Status,BytesSent,BytesRecv,TimeTaken,ProtocolVersion,Host,UserAgent,Cookie,Referer"
$website.logFile.localTimeRollover = "True"
$website.logFile.enabled = "True"
$website | Set-Item -path "IIS:\Sites\$siteName"

New-Item -path "${root}" -name "${folder}" -itemtype "directory"
& icacls $sitefolder /grant "Everyone:(OI)(CI)F"
