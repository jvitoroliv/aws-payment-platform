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
  $WSFCStaticIP,

  [Parameter(Mandatory = $true)]
  [string]
  $ClusterName,

  [Parameter(Mandatory = $true)]
  [string]
  $NetBiosDomainName,

  [Parameter(Mandatory = $true)]
  [string]
  $DomainDnsName,

  [Parameter(Mandatory = $true)]
  [string]$SQLSvcAcctCredentialsARN
)

# Get the DSC Cert Encryption Thumbprint to Secure the MOF File
$DscCertThumbprint = (Get-ChildItem -path cert:\LocalMachine\My | Where-Object { $_.subject -eq "CN=SQLClusterEncryptCert" }).Thumbprint

# Get Password for AD Admin User from Secrets Manager
$DomainAdminPassword = (Get-SECSecretValue -SecretId $DomainAdminPasswordARN).SecretString

# Create a PSCredential object of the AD domain admin:
$DomainAdminUser = $NetBiosDomainName + '\' + $DomainAdminUser
$ADCredentials = (New-Object PSCredential($DomainAdminUser, (ConvertTo-SecureString $DomainAdminPassword -AsPlainText -Force)))

# Get SQL service account user & password from Secrets Manager:
# $SQLSvcAcctCredsFromSecretsMgr = ConvertFrom-JSON -InputObject (Get-SECSecretValue -SecretId $SQLSvcAcctCredentialsARN).SecretString
# $SQLSvcAcctUser = $SQLSvcAcctCredsFromSecretsMgr.Userid
# $SQLSvcAcctUserAD = $NetBiosDomainName + '\' + $SQLSvcAcctUser

$ConfigurationData = @{
  AllNodes = @(
    @{
      NodeName = "*"
      CertificateFile = "C:\SQLClusterDSCConfig\publickeys\SQLClusterEncryptCert.cer"
      Thumbprint = $DscCertThumbprint
      PSDscAllowDomainUser = $true
    },
    @{
      NodeName = 'localhost'
    }
  )
}

Configuration SecondaryNodeConfig {
  param(
    [PSCredential] $ADCredentials
  )

  Import-Module -Name PSDscResources
  Import-Module -Name xFailOverCluster

  Import-DscResource -Module PSDscResources
  Import-DscResource -ModuleName xFailOverCluster

  Node 'localhost' {

    Group Administrators {
      GroupName = 'Administrators'
      Ensure = 'Present'
      MembersToInclude = @($DomainAdminUser)
    }

    xWaitForCluster WaitForCluster {
      Name             = $ClusterName
      RetryIntervalSec = 10
      RetryCount       = 600
    }

    xCluster JoinSecondNodeToCluster {
      Name                          = $ClusterName
      StaticIPAddress               = $WSFCStaticIP
      DomainAdministratorCredential = $ADCredentials
      DependsOn                     = '[xWaitForCluster]WaitForCluster', '[Group]Administrators'
    }

  }
}

SecondaryNodeConfig -OutputPath 'C:\SQLClusterDSCConfig\SecondaryNodeConfig' -ConfigurationData $ConfigurationData -ADCredentials $ADCredentials
