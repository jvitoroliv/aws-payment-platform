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
    $SQLInstanceName,

    [Parameter(Mandatory = $true)]
    [string]
    $ClusterName,
    
    [Parameter(Mandatory = $true)]
    [string]
    $SQLClusterNetworkName,

    [Parameter(Mandatory = $true)]
    [string]
    $EncFI
)

# Get the DSC Cert Encryption Thumbprint to Secure the MOF File
$DscCertThumbprint = (Get-ChildItem -path cert:\LocalMachine\My | Where-Object { $_.subject -eq "CN=SQLClusterEncryptCert" }).Thumbprint

# Get Password for AD Admin User from Secrets Manager
$DomainAdminPassword = (Get-SECSecretValue -SecretId $DomainAdminPasswordARN).SecretString

# Create a PSCredential object of the AD domain admin:
$DomainAdminUser = $NetBiosDomainName + '\' + $DomainAdminUser
$ADCredentials = (New-Object PSCredential($DomainAdminUser, (ConvertTo-SecureString $DomainAdminPassword -AsPlainText -Force)))

# Get SQL service account user & password from Secrets Manager:
$SQLSvcAcctCredsFromSecretsMgr = ConvertFrom-JSON -InputObject (Get-SECSecretValue -SecretId $SQLSvcAcctCredentialsARN).SecretString
$SQLSvcAcctUser = $SQLSvcAcctCredsFromSecretsMgr.Userid
$SQLSvcAcctPassword = $SQLSvcAcctCredsFromSecretsMgr.Password
$SQLSvcAcctUserAD = $NetBiosDomainName + '\' + $SQLSvcAcctUser
# Create a PSCredential object of the SQL service account creds:
$SQLSvcAcctCredentials = (New-Object PSCredential($SQLSvcAcctUserAD, (ConvertTo-SecureString $SQLSvcAcctPassword -AsPlainText -Force)))


# Extract Install from Downloaded ISO
New-Item -Path C:\SQLClusterDSCConfig\SQLMediaExpanded -ItemType Directory -Force
$sql2017_iso_name = "en_sql_server_2017_enterprise_core_x64_dvd_11293037.iso"
$ImagePath = "C:\SQLClusterDSCConfig\SQLMedia\" + $sql2017_iso_name 

$mountResult = Mount-DiskImage -ImagePath $ImagePath -PassThru
$volumeInfo = $mountResult | Get-Volume
$driveInfo = Get-PSDrive -Name $volumeInfo.DriveLetter
Copy-Item -Path ( Join-Path -Path $driveInfo.Root -ChildPath '*' ) -Destination C:\SQLClusterDSCConfig\SQLMediaExpanded\ -Recurse -Force
Dismount-DiskImage -ImagePath $ImagePath


$ConfigurationData = @{
    AllNodes = @(
        @{
            NodeName                    = "*"
            CertificateFile             = "C:\SQLClusterDSCConfig\publickeys\SQLClusterEncryptCert.cer"
            Thumbprint                  = $DscCertThumbprint
            PSDscAllowDomainUser        = $true
        },
        @{
            NodeName = 'localhost'
        }
    )
}

Configuration SQLInstallSecondaryNode {
    [CmdletBinding()]
    param (
        [PSCredential] $ADCredentials,
        [PSCredential] $SQLSvcAcctCredentials,
        [string] $SQLSvcAcctUserAD,
        [string] $SQLInstanceName,
        [string] $SQLClusterNetworkName,
        [string] $EncFI
    )

    Import-Module -Name PSDesiredStateConfiguration
    Import-Module -Name SqlServerDsc

    Import-DscResource -Module PSDesiredStateConfiguration
    Import-DscResource -Module SqlServerDsc

    node 'localhost' {
        WindowsFeature 'NetFramework35' {
            Name   = 'NET-Framework-Core'
            Ensure = 'Present'
        }

        WindowsFeature 'NetFramework45' {
            Name   = 'NET-Framework-45-Core'
            Ensure = 'Present'
        }

        # Wait for the Cluster Network resource for SQL Server to come online
        Script WaitForClusterNetwork {

            TestScript = {
                $networkName = $using:SQLClusterNetworkName
                return (Get-ClusterResource -Name "*$($networkName)*" | Where-Object { $_.ResourceType -eq "Network Name" }) -ne $null
            }

            SetScript = {
                $networkName = $using:SQLClusterNetworkName
                $RetryInterval = 30
                $RetryCount = 200

                while ($RetryCount -gt 0) {
                    $resource = Get-ClusterResource -Name "*$($networkName)*" | Where-Object { $_.ResourceType -eq "Network Name" }
                    if ($resource -ne $null) {
                        return $resource
                    }

                    $RetryCount = $RetryCount - 1
                    Start-Sleep -Seconds $RetryInterval
                }
            }

            GetScript = {
                $networkName = $using:SQLClusterNetworkName
                return @{ SQLClusterNetworkName = Get-ClusterResource -Name "*$($networkName)*" | Where-Object { $_.ResourceType -eq "Network Name" } }
            }
        }


        SqlSetup 'InstallDefaultInstance' {
            Action                     = 'AddNode'
            ForceReboot                = $false
            UpdateEnabled              = 'False'

            SourcePath                 = "C:\SQLClusterDSCConfig\SQLMediaExpanded"

            InstanceName               = "${SQLInstanceName}"
            Features                   = 'SQLENGINE,Replication,FullText,DQ'

            SQLCollation               = 'SQL_Latin1_General_CP1_CI_AS'

            SQLSvcAccount              = $SQLSvcAcctCredentials
            AgtSvcAccount              = $SQLSvcAcctCredentials
            SQLSysAdminAccounts        = $DomainAdminUser

            FailoverClusterNetworkName = $SQLClusterNetworkName

            PsDscRunAsCredential       = $ADCredentials

            DependsOn                  = '[WindowsFeature]NetFramework35', '[WindowsFeature]NetFramework45', '[Script]WaitForClusterNetwork'
        }

        Script SetFileSystemPermission {
            SetScript = {
                # Set permissions for SQL Service Account
                $user_account = $using:SQLSvcAcctUserAD

                $path = "C:\ClusterStorage\$($using:EncFI)_Archive"
                $acl = Get-Acl $path
                $rule = New-Object system.Security.AccessControl.FileSystemAccessRule($user_account, "FullControl", "ContainerInherit, ObjectInherit", "None", "Allow")
                $acl.Setaccessrule($rule)
                Set-Acl $path $acl

                $path = "C:\ClusterStorage\$($using:EncFI)_Backup"
                $acl = Get-Acl $path
                $rule = New-Object system.Security.AccessControl.FileSystemAccessRule($user_account, "FullControl", "ContainerInherit, ObjectInherit", "None", "Allow")
                $acl.Setaccessrule($rule)
                Set-Acl $path $acl

                $path = "C:\ClusterStorage\$($using:EncFI)_CoreService"
                $acl = Get-Acl $path
                $rule = New-Object system.Security.AccessControl.FileSystemAccessRule($user_account, "FullControl", "ContainerInherit, ObjectInherit", "None", "Allow")
                $acl.Setaccessrule($rule)
                Set-Acl $path $acl
            }

            TestScript = {
                return $false
            }

            GetScript = {
                return @{Result = "" }
            }

            PsDscRunAsCredential = $ADCredentials
            DependsOn  = '[SqlSetup]InstallDefaultInstance'
        }
    }
}

SQLInstallSecondaryNode -OutputPath 'C:\SQLClusterDSCConfig\SQLInstall' -ConfigurationData $ConfigurationData -ADCredentials $ADCredentials -SQLSvcAcctCredentials $SQLSvcAcctCredentials -SQLInstanceName $SQLInstanceName -SQLSvcAcctUserAD $SQLSvcAcctUserAD -SQLClusterNetworkName $SQLClusterNetworkName -EncFI $EncFI
