[CmdletBinding()]
param()

Write-Output "Setting up Powershell Gallery to Install DSC Modules"
Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force
Set-PSRepository -Name PSGallery -InstallationPolicy Trusted

Write-Output "Installing the required Powershell DSC modules"
Install-Module -Name SqlServerDsc
Install-Module -Name ComputerManagementDsc
Install-Module -Name "xFailOverCluster"
Install-Module -Name PSDscResources
Install-Module -Name xSmbShare
Install-Module -Name "xActiveDirectory"
# Install-Module SqlServer -Force -AllowClobber

Write-Output "Disabling Windows Firewall"
Get-NetFirewallProfile | Set-NetFirewallProfile -Enabled False

# AWS recommendations for Cluster on EC2
# Commented out as they were found to crash the servers.
# See for more info: https://amzn.to/2ywiXCa
# if ( (Get-NetQosPolicy -name "ClusterQoS" -ea 0).Name -eq $null) {
#    New-NetQosPolicy -Name "ClusterQoS" -Cluster -Priority 6
# }
# Get-NetAdapter | Set-NetAdapterAdvancedProperty -DisplayName "MTU" -DisplayValue 9001
netsh int ipv6 isatap set state disabled

Write-Output "Creating Directory for DSC Public Cert"
New-Item -Path C:\SQLClusterDSCConfig\publickeys -ItemType directory -Force

Write-Output "Setting up DSC Certificate to Encrypt Credentials in MOF File"
If (-Not (Get-ChildItem -path cert:\LocalMachine\My | Where-Object { $_.subject -eq "CN=SQLClusterEncryptCert" })) {
  $cert = New-SelfSignedCertificate -Type DocumentEncryptionCertLegacyCsp -DnsName 'SQLClusterEncryptCert' -HashAlgorithm SHA256
  # Exporting the public key certificate
    $cert | Export-Certificate -FilePath "C:\SQLClusterDSCConfig\publickeys\SQLClusterEncryptCert.cer" -Force
}
