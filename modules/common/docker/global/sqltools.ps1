# load chocolatey, then SSMS, so that AutoBuildNexGen can run
iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))
choco feature enable -n allowGlobalConfirmation

# Install SQL Server Management Studio 17.9.1 14.0.17289.1
write-host ""
write-host "===> Installing SSMS"
choco install sql-server-management-studio --version 14.0.17289.1
$env:Path+="C:\Program Files (x86)\Microsoft SQL Server\Client SDK\ODBC\130\Tools\Binn;"

####Install DAC Frame work####
write-host ""
write-host "===> Installing DACframework"
# Can't use choco because we need a specific version, 15.0.4897.1, which the current dacfx18.1 doesn't include: https://chocolatey.org/packages/DacFx-18
New-Item -Path "c:\" -Name "install" -ItemType "directory"
write-host "...downloading"
Invoke-WebRequest -Uri "https://go.microsoft.com/fwlink/?linkid=2143544" -Outfile c:\install\dacframework.msi
write-host "...installing"
Start-Process "msiexec.exe" -ArgumentList "/i c:\install\dacframework.msi /qn /norestart /quiet" -passthru | wait-process

###v2013c++
write-host ""
write-host "===> Installing C++redist"
choco install msvisualcplusplus2013-redist