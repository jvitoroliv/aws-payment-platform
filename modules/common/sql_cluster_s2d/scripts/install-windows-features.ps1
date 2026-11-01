[CmdletBinding()]
param()

# Getting the DSC Cert Encryption Thumbprint to Secure the MOF File
$DscCertThumbprint = (Get-ChildItem -path cert:\LocalMachine\My | Where-Object { $_.subject -eq "CN=SQLClusterEncryptCert" }).Thumbprint


$ConfigurationData = @{
    AllNodes = @(
        @{
            NodeName             = "*"
            CertificateFile      = "C:\SQLClusterDSCConfig\publickeys\SQLClusterEncryptCert.cer"
            Thumbprint           = $DscCertThumbprint
            PSDscAllowDomainUser = $true
        },
        @{
            NodeName = 'localhost'
        }
    )
}

Configuration AddWindowsFeatures {
    [CmdletBinding()]
    param()

    Import-Module -Name PSDesiredStateConfiguration

    Import-DscResource -Module PSDesiredStateConfiguration

    node 'localhost' {
        WindowsFeature RSAT-AD-PowerShell {
            Name = 'RSAT-AD-PowerShell'
            Ensure = 'Present'
        }

        WindowsFeature AddRemoteServerAdministrationToolsClusteringFeature {
            Ensure    = 'Present'
            Name      = 'RSAT-Clustering-Mgmt'
            DependsOn = '[WindowsFeature]AddFailoverFeature'
        }

        WindowsFeature AddRemoteServerAdministrationToolsClusteringPowerShellFeature {
            Ensure    = 'Present'
            Name      = 'RSAT-Clustering-PowerShell'
            DependsOn = '[WindowsFeature]AddRemoteServerAdministrationToolsClusteringFeature'
        }

        WindowsFeature AddRemoteServerAdministrationToolsClusteringCmdInterfaceFeature {
            Ensure    = 'Present'
            Name      = 'RSAT-Clustering-CmdInterface'
            DependsOn = '[WindowsFeature]AddRemoteServerAdministrationToolsClusteringPowerShellFeature'
        }

        WindowsFeature AddFailoverFeature {
            Ensure    = 'Present'
            Name      = 'Failover-clustering'
            DependsOn = '[WindowsFeature]RSAT-AD-PowerShell'
        }
    }
}

AddWindowsFeatures -OutputPath 'C:\SQLClusterDSCConfig\AddWindowsFeatures' -ConfigurationData $ConfigurationData 
