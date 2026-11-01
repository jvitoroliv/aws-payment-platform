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
    $Node2ClusterIP,
    
    [Parameter(Mandatory = $true)]
    [string]
    $ClusterName,

    [Parameter(Mandatory = $true)]
    [string]
    $EncFI,

    # Active Directory domain name; e.g. DEV
    [Parameter(Mandatory = $true)]
    [string]
    $NetBiosDomainName,

    # StoragePools
    [Parameter(Mandatory = $true)]
    [string]
    $DefaultPoolEBSVolumes,

    [Parameter(Mandatory = $true)]
    [string]
    $FCIPoolEBSVolumes,

    [Parameter(Mandatory = $true)]
    [string]
    $CorePlatformPoolEBSVolumes,

    [Parameter(Mandatory = $true)]
    [string]
    $ArchivePoolEBSVolumes,

    [Parameter(Mandatory = $true)]
    [string]
    $BackupPoolEBSVolumes,

    # DNS name; e.g. dev.ad.example.com
    [Parameter(Mandatory = $true)]
    [string]$DomainDnsName,

    [Parameter(Mandatory = $true)]
    [string]$SQLSvcAcctCredentialsARN,

    [Parameter(Mandatory = $true)]
    [string]$SQLClusterNetworkName
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

# Cluster's object name in Active Directory:
$ClusterNameID = $NetBiosDomainName + '\' + $ClusterName + '$'  # e.g.: dev\ClusterName$

# Path to Computers OU in Active Directory:
$ComputersOUPath = (Get-ADDomain $DomainDnsName).ComputersContainer


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

Configuration PrimaryNodeConfig {
    param(
        [PSCredential] $ADCredentials,
        [PSCredential] $SQLSvcAcctCredentials
    )

    Import-Module -Name PSDscResources
    Import-Module -Name xFailOverCluster
    Import-Module -Name xActiveDirectory

    Import-DscResource -Module PSDscResources
    Import-DscResource -ModuleName xFailOverCluster
    Import-DscResource -ModuleName xActiveDirectory

    node 'localhost' {

        xADUser SQLServiceAccount {
            DomainName                    = $DomainDnsName
            UserName                      = $SQLSvcAcctUser
            Password                      = $SQLSvcAcctCredentials
            DisplayName                   = $SQLSvcAcctUser
            PasswordAuthentication        = 'Negotiate'
            DomainAdministratorCredential = $ADCredentials
            Ensure                        = 'Present'
        }

        #TODO: add DBAdmin AD group

        Group Administrators {
            GroupName        = 'Administrators'
            Ensure           = 'Present'
            MembersToInclude = @($DomainAdminUser)
            DependsOn        = "[xADUser]SQLServiceAccount"
        }

        xADComputer 'ClusterNameAccount'
        {
            ComputerName         = $ClusterName
            Description          = "Cluster Name Object (CNO) for ${EncFI} - ${NetBiosDomainName}"
            EnabledOnCreation    = $false
            PsDscRunAsCredential = $ADCredentials
        }

        # Wait to ensure CNO Computer object is fully replicated in AD
        # (needed due to intermittent issue with duplicate 'CNF' object getting created)
        Script 'WaitForADReplication'
        {
            TestScript = { return $false }
            SetScript  = { Start-Sleep -Seconds 60 }
            GetScript  = { return $@ { } }
            DependsOn  = '[xADComputer]ClusterNameAccount'
        }

        xADObjectPermissionEntry 'PermissionsForCNO'
        {
            Ensure                             = 'Present'
            Path                               = $ComputersOUPath
            IdentityReference                  = $ClusterNameID
            ActiveDirectoryRights              = 'GenericAll'
            AccessControlType                  = 'Allow'
            ObjectType                         = '00000000-0000-0000-0000-000000000000'
            ActiveDirectorySecurityInheritance = 'All'
            InheritedObjectType                = '00000000-0000-0000-0000-000000000000'
            PsDscRunAsCredential               = $ADCredentials
            DependsOn                          = '[xADComputer]ClusterNameAccount'
        }

        xADComputer 'VirtualSQLClusterName'
        {
            ComputerName         = $SQLClusterNetworkName
            Description          = "Virtual SQL Cluster Network Name for ${EncFI} - ${NetBiosDomainName}"
            PsDscRunAsCredential = $ADCredentials
        }

        xCluster CreateCluster {
            Name                          = $ClusterName
            StaticIPAddress               = $WSFCStaticIP
            DomainAdministratorCredential = $ADCredentials
            DependsOn                     = '[Group]Administrators', '[xADComputer]ClusterNameAccount', '[xADObjectPermissionEntry]PermissionsForCNO'
        }

        xADObjectEnabledState 'EnableCNO'
        {
            Identity             = $ClusterName
            ObjectClass          = 'Computer'
            Enabled              = $true
            PsDscRunAsCredential = $ADCredentials
            DependsOn            = '[xCluster]CreateCluster'
        }

        xWaitForCluster 'WaitForCluster' {
            Name             = $ClusterName
            RetryIntervalSec = 10
            RetryCount       = 600
            DependsOn        = '[xADObjectEnabledState]EnableCNO'
        }

        # This is necessary since the xCluster DSC resource currently can not handle multiple Cluster IPs.
        # Open issue: https://github.com/PowerShell/xFailOverCluster/issues/33 & https://github.com/PowerShell/xFailOverCluster/issues/32
        Script AddFailoverClusterIPs {
            # Cluster IP address resources are called: Node<x>ClusterIP. e.g.: Node2ClusterIP
            SetScript = {
                # Local vars of the Cluster IPs:
                $Node1ClusterIP = $using:WSFCStaticIP
                $Node2ClusterIP = $using:Node2ClusterIP

                # Rename the 1st cluster resource IP to 'Node1IP'
                # Assumes it still has the default name of "Cluster IP Address"
                if ( -not( Get-ClusterResource | Where-Object { $_.Name -eq "Node1ClusterIP" } )) { 
                    (Get-ClusterResource | Where-Object { ($_.ResourceType -eq "IP address") -and ($_.Name -match "Cluster IP Address") } ).Name = "Node1ClusterIP"
                }

                # Create the IP Address resources of the secondary nodes
                # Node #2:
                $Timeout = 1200 ## seconds
                $CheckEvery = 5 ## seconds
                $timer = [Diagnostics.Stopwatch]::StartNew()
                while ( -not(Get-ClusterNetwork -Name "Cluster network 2" -ErrorAction SilentlyContinue) -or (Get-ClusterNetwork -name "Cluster Network 2").State -eq "Down") { 
                    if ($timer.Elapsed.TotalSeconds -ge $Timeout) {
                        Write-Verbose "Timeout exceeded. Giving up waiting for Cluster Network 2."
                        break
                    }
                    Write-Verbose "Cluster network 2 not found yet..."
                    Start-Sleep -Seconds $CheckEvery
                }
                $timer.Stop()
                Write-Verbose "Found cluster network 2. Adding Cluster IP of Node2"
                Get-ClusterGroup | Where-Object Name -like "*Group*" | Add-ClusterResource -Name Node2ClusterIP -ResourceType "IP Address"  -ErrorAction SilentlyContinue
                Get-ClusterResource -Name "Node2ClusterIP" | Set-ClusterParameter -Multiple @{"Address" = "$Node2ClusterIP"; "SubnetMask" = "255.255.255.0" }  -ErrorAction SilentlyContinue

                # Now set up Dependency on Cluster's Cluster Name resource
                Set-ClusterResourceDependency -Cluster $using:ClusterName -Resource "Cluster Name" -Dependency "[Node1ClusterIP] or [Node2ClusterIP]"
            }

            TestScript = {
                # Local vars of the Cluster IPs:
                $Node1ClusterIP = $using:WSFCStaticIP
                $Node2ClusterIP = $using:Node2ClusterIP
                $depOK = $true

                try {
                    # Tests whether there are 3 IPs in the dependency list
                    $dep = (Get-ClusterResourceDependency -cluster $using:ClusterName -resource "Cluster Name" -ErrorAction SilentlyContinue)."DependencyExpression"
                    $separator = " or "
                    if ( ($dep -split $separator).count -ne 3 ) { $depOK = $false }

                    # Do the IP Address resources exist?
                    # And if they do, check if the IPs are assigned to the IP Address resources:
                    # Node #2:
                    if ( -not( Get-ClusterResource | Where-Object { $_.Name -eq "Node2ClusterIP" } )) { 
                        Write-Verbose -Message "Node2ClusterIP IP Address resource does not exist."
                        $depOK = $false
                    }
                    elseif ( -not((Get-ClusterResource -Name "Node2ClusterIP" | Get-ClusterParameter -Name Address).Value -eq $Node2ClusterIP) ) {
                        Write-Verbose -Message "Node2ClusterIP does not have its IP Address set correctly."
                        $depOK = $false
                    }

                    Write-Verbose -Message "The Cluster's IP Dependency is currently set to: $dep"
                    return $depOK
                }
                catch { 
                    return $false
                }
            }

            GetScript = {
                return @{ ClusterResourceDependency = Get-ClusterResourceDependency -Cluster $using:ClusterName -Resource "Cluster Name" -ErrorAction SilentlyContinue }
            }

            PsDscRunAsCredential = $ADCredentials
            DependsOn  = '[xCluster]CreateCluster', '[xWaitForCluster]WaitForCluster'
        }

        # Enable Storage Spaces Direct (S2D)
        Script EnableS2D {
            SetScript  = {
                Enable-ClusterS2D -AutoConfig:$false  -Confirm:$false -SkipEligibilityChecks:$true
            }

            TestScript = {
                (Get-ClusterS2D -WarningAction SilentlyContinue).State -eq 'Enabled'
            }

            GetScript  = {
                @{Ensure = if ((Get-ClusterS2D -WarningAction SilentlyContinue).State -eq 'Enabled') { 'Present' } Else { 'Absent' } }
            }

            Credential = $ADCredentials
            DependsOn  = "[xCluster]CreateCluster"
        }

        # Create S2D Pools. Using a DSC 'Script' Resource as there was no DSC resource for S2D pools.
        # Default Pool
        Script S2DPool_Default {
            SetScript = {
                $friendlyName = "DefaultPool"
                $diskNames = ($using:DefaultPoolEBSVolumes).Split(",").ForEach{ "$($_.Replace("vol-", "vol"))_00000001." }
                $physicalDisks = $diskNames.ForEach{ Get-PhysicalDisk -SerialNumber $_ -CanPool:$true }

                # If pool exists, add any new disks not already in the pool, else create it.
                if (Get-StoragePool -FriendlyName $friendlyName -ErrorAction SilentlyContinue) {
                    # if # of physical disks not equal to # of disks in pool, add them
                    $pool = Get-StoragePool -FriendlyName $friendlyName
                    if ( ($using:DefaultPoolEBSVolumes).Split(",").length -ne ($pool | Get-PhysicalDisk).length ) {
                        $pool | Add-PhysicalDisk -PhysicalDisks $physicalDisks
                        Write-Verbose "Adding additional physical disks to the $friendlyName Storage Pool"
                    }
                }
                else {
                    if ($physicalDisks.count -lt 3) {
                        Write-Verbose "There are not at least 3 disks to create $friendlyName Storage Pool. Add additional disks and re-try."
                    }
                    else {
                        Get-StorageSubSystem Cluster* | New-StoragePool -FriendlyName $friendlyName -PhysicalDisks $physicalDisks
                        Write-Verbose "Created $friendlyName Storage Pool "
                    }
                }
            }

            TestScript = {
                try {
                    $pool = Get-StoragePool -FriendlyName DefaultPool -ErrorAction Stop
                    return ($using:DefaultPoolEBSVolumes).Split(",").length -eq ($pool | Get-PhysicalDisk).length 
                }
                catch {
                    return $false
                }
            }

            GetScript = {
                $pool = Get-StoragePool -FriendlyName DefaultPool -ErrorAction Stop
                $disk = $pool | Get-PhysicalDisk
                return @{ S2DPool_Default = $disk }
            }

            Credential = $ADCredentials
            DependsOn  = "[Script]EnableS2D"
        }

        # FCI Pool
        Script S2DPool_FCI {
            SetScript = {
                $friendlyName = "FCIPool"
                $diskNames = ($using:FCIPoolEBSVolumes).Split(",").ForEach{ "$($_.Replace("vol-", "vol"))_00000001." }
                $physicalDisks = $diskNames.ForEach{ Get-PhysicalDisk -SerialNumber $_ -CanPool:$true }

                # If pool exists, add any new disks not already in the pool, else create it.
                if (Get-StoragePool -FriendlyName $friendlyName -ErrorAction SilentlyContinue) {
                    # if # of physical disks not equal to # of disks in pool, add them
                    $pool = Get-StoragePool -FriendlyName $friendlyName
                    if ( ($using:FCIPoolEBSVolumes).Split(",").length -ne ($pool | Get-PhysicalDisk).length ) {
                        $pool | Add-PhysicalDisk -PhysicalDisks $physicalDisks
                        Write-Verbose "Adding additional physical disks to the $friendlyName Storage Pool"
                    }
                }
                else {
                    if ($physicalDisks.count -lt 3) {
                        Write-Verbose "There are not at least 3 disks to create $friendlyName Storage Pool. Add additional disks and re-try."
                    }
                    else {
                        Get-StorageSubSystem Cluster* | New-StoragePool -FriendlyName $friendlyName -PhysicalDisks $physicalDisks
                        Write-Verbose "Created $friendlyName Storage Pool "
                    }
                }

                # If there isn't a Storage Cluster Volume (CSV), create it
                $EncFI = $using:EncFI
                if (-Not (Get-Volume -FriendlyName "${EncFI}_FCI" -ErrorAction SilentlyContinue)) {
                    New-Volume -FriendlyName "${EncFI}_FCI" -FileSystem "CSVFS_ReFS" -StoragePoolFriendlyName $friendlyName  -UseMaximumSize -ProvisioningType "Fixed"
                    Write-Verbose "Created ${EncFI} FCI Cluster Storage Volume (CSV)"
                }
            }

            TestScript = {
                try {
                    $EncFI = $using:EncFI
                    $pool = Get-StoragePool -FriendlyName FCIPool -ErrorAction Stop
                    ( ($using:FCIPoolEBSVolumes).Split(",").length -eq ($pool | Get-PhysicalDisk).length ) -and ( Get-Volume -FriendlyName "${EncFI}_FCI" -ErrorAction SilentlyContinue )
                }
                catch {
                    return $false
                }
            }

            GetScript = {
                $pool = Get-StoragePool -FriendlyName FCIPool -ErrorAction Stop
                $disk = $pool | Get-PhysicalDisk
                return @{ S2DPool_FCI = $disk }
            }

            Credential = $ADCredentials
            DependsOn  = "[Script]EnableS2D"
        }

        # CorePlatform Pool
        Script S2DPool_CorePlatform {
            SetScript = {
                $friendlyName = "CorePlatformPool"
                $diskNames = ($using:CorePlatformPoolEBSVolumes).Split(",").ForEach{ "$($_.Replace("vol-", "vol"))_00000001." }
                $physicalDisks = $diskNames.ForEach{ Get-PhysicalDisk -SerialNumber $_ -CanPool:$true }

                # If pool exists, add any new disks not already in the pool, else create it.
                if (Get-StoragePool -FriendlyName $friendlyName -ErrorAction SilentlyContinue) {
                    # if # of physical disks not equal to # of disks in pool, add them
                    $pool = Get-StoragePool -FriendlyName $friendlyName
                    if ( ($using:CorePlatformPoolEBSVolumes).Split(",").length -ne ($pool | Get-PhysicalDisk).length ) {
                        $pool | Add-PhysicalDisk -PhysicalDisks $physicalDisks
                        Write-Verbose "Adding additional physical disks to the $friendlyName Storage Pool"
                    }
                }
                else {
                    if ($physicalDisks.count -lt 3) {
                        Write-Verbose "There are not at least 3 disks to create $friendlyName Storage Pool. Add additional disks and re-try."
                    }
                    else {
                        Get-StorageSubSystem Cluster* | New-StoragePool -FriendlyName $friendlyName -PhysicalDisks $physicalDisks
                        Write-Verbose "Created $friendlyName Storage Pool "
                    }
                }

                # If there isn't a Storage Cluster Volume (CSV), create it
                $EncFI = $using:EncFI
                if (-Not (Get-Volume -FriendlyName "${EncFI}_CoreService" -ErrorAction SilentlyContinue)) {
                    New-Volume -FriendlyName "${EncFI}_CoreService" -FileSystem "CSVFS_ReFS" -StoragePoolFriendlyName $friendlyName  -UseMaximumSize -ProvisioningType "Fixed"
                    Write-Verbose "Created ${EncFI} CoreService Cluster Storage Volume (CSV)"
                }
            }

            TestScript = {
                try {
                    $EncFI = $using:EncFI
                    $pool = Get-StoragePool -FriendlyName CorePlatformPool -ErrorAction Stop
                    ( ($using:CorePlatformPoolEBSVolumes).Split(",").length -eq ($pool | Get-PhysicalDisk).length ) -and ( Get-Volume -FriendlyName "${EncFI}_CoreService" -ErrorAction SilentlyContinue)
                }
                catch {
                    return $false
                }
            }

            GetScript = {
                $pool = Get-StoragePool -FriendlyName CorePlatformPool -ErrorAction Stop
                $disk = $pool | Get-PhysicalDisk
                return @{ S2DPool_CorePlatform = $disk }
            }

            Credential = $ADCredentials
            DependsOn  = "[Script]EnableS2D"
        }

        # Archive Pool
        Script S2DPool_Archive {
            SetScript = {
                $friendlyName = "ArchivePool"
                $diskNames = ($using:ArchivePoolEBSVolumes).Split(",").ForEach{ "$($_.Replace("vol-", "vol"))_00000001." }
                $physicalDisks = $diskNames.ForEach{ Get-PhysicalDisk -SerialNumber $_ -CanPool:$true }

                # If pool exists, add any new disks not already in the pool, else create it.
                if (Get-StoragePool -FriendlyName $friendlyName -ErrorAction SilentlyContinue) {
                    # if # of physical disks not equal to # of disks in pool, add them
                    $pool = Get-StoragePool -FriendlyName $friendlyName
                    if ( ($using:ArchivePoolEBSVolumes).Split(",").length -ne ($pool | Get-PhysicalDisk).length ) {
                        $pool | Add-PhysicalDisk -PhysicalDisks $physicalDisks
                        Write-Verbose "Adding additional physical disks to the $friendlyName Storage Pool"
                    }
                }
                else {
                    if ($physicalDisks.count -lt 3) {
                        Write-Verbose "There are not at least 3 disks to create $friendlyName Storage Pool. Add additional disks and re-try."
                    }
                    else {
                        Get-StorageSubSystem Cluster* | New-StoragePool -FriendlyName $friendlyName -PhysicalDisks $physicalDisks
                        Write-Verbose "Created $friendlyName Storage Pool "
                    }
                }

                # If there isn't a Storage Cluster Volume (CSV), create it
                $EncFI = $using:EncFI
                if (-Not (Get-Volume -FriendlyName "${EncFI}_Archive" -ErrorAction SilentlyContinue)) {
                    New-Volume -FriendlyName "${EncFI}_Archive" -FileSystem "CSVFS_ReFS" -StoragePoolFriendlyName $friendlyName  -UseMaximumSize -ProvisioningType "Fixed"
                    Write-Verbose "Created ${EncFI} Archive Cluster Storage Volume (CSV)"
                }
            }

            TestScript = {
                try {
                    $EncFI = $using:EncFI
                    $pool = Get-StoragePool -FriendlyName ArchivePool -ErrorAction Stop
                    ( ($using:ArchivePoolEBSVolumes).Split(",").length -eq ($pool | Get-PhysicalDisk).length ) -and ( Get-Volume -FriendlyName "${EncFI}_Archive" -ErrorAction SilentlyContinue)
                }
                catch {
                    return $false
                }
            }

            GetScript = {
                $pool = Get-StoragePool -FriendlyName ArchivePool -ErrorAction Stop
                $disk = $pool | Get-PhysicalDisk
                return @{ S2DPool_Archive = $disk }
            }

            Credential = $ADCredentials
            DependsOn  = "[Script]EnableS2D"
        }

        # Backup Pool
        Script S2DPool_Backup {
            SetScript = {
                $friendlyName = "BackupPool"
                $diskNames = ($using:BackupPoolEBSVolumes).Split(",").ForEach{ "$($_.Replace("vol-", "vol"))_00000001." }
                $physicalDisks = $diskNames.ForEach{ Get-PhysicalDisk -SerialNumber $_ -CanPool:$true }

                # If pool exists, add any new disks not already in the pool, else create it.
                if (Get-StoragePool -FriendlyName $friendlyName -ErrorAction SilentlyContinue) {
                    # if # of physical disks not equal to # of disks in pool, add them
                    $pool = Get-StoragePool -FriendlyName $friendlyName
                    if ( ($using:BackupPoolEBSVolumes).Split(",").length -ne ($pool | Get-PhysicalDisk).length ) {
                        $pool | Add-PhysicalDisk -PhysicalDisks $physicalDisks
                        Write-Verbose "Adding additional physical disks to the $friendlyName Storage Pool"
                    }
                }
                else {
                    if ($physicalDisks.count -lt 3) {
                        Write-Verbose "There are not at least 3 disks to create $friendlyName Storage Pool. Add additional disks and re-try."
                    }
                    else {
                        Get-StorageSubSystem Cluster* | New-StoragePool -FriendlyName $friendlyName -PhysicalDisks $physicalDisks
                        Write-Verbose "Created $friendlyName Storage Pool "
                    }
                }

                # If there isn't a Storage Cluster Volume (CSV), create it
                $EncFI = $using:EncFI
                if (-Not (Get-Volume -FriendlyName "${EncFI}_Backup" -ErrorAction SilentlyContinue)) {
                    New-Volume -FriendlyName "${EncFI}_Backup" -FileSystem "CSVFS_ReFS" -StoragePoolFriendlyName $friendlyName  -UseMaximumSize -ProvisioningType "Fixed"
                    Write-Verbose "Created ${EncFI} Backup Cluster Storage Volume (CSV)"
                }
            }

            TestScript = {
                try {
                    $EncFI = $using:EncFI
                    $pool = Get-StoragePool -FriendlyName BackupPool -ErrorAction Stop
                    ( ($using:BackupPoolEBSVolumes).Split(",").length -eq ($pool | Get-PhysicalDisk).length ) -and ( Get-StoragePool -FriendlyName "${EncFI}_Backup" -ErrorAction SilentlyContinue)
                }
                catch {
                    return $false
                }
            }

            GetScript = {
                $pool = Get-StoragePool -FriendlyName BackupPool -ErrorAction Stop
                $disk = $pool | Get-PhysicalDisk
                return @{ S2DPool_Backup = $disk }
            }

            Credential = $ADCredentials
            DependsOn  = "[Script]EnableS2D"
        }

        # Rename Pools' Friendly Names according to naming standards
        Script S2DPools_FriendlyNames {
            SetScript = {
                foreach ($pool in Get-StoragePool -IsPrimordial:$false) {
                    $poolName = $pool.FriendlyName
                    $poolId = $pool.UniqueId.Substring(1, 36)
                    $clusterResource = Get-ClusterResource -Cluster $using:ClusterName | Where-Object Id -eq $poolId

                    if ($clusterResource.Name -ne $poolName) {
                        $clusterResource.Name = $poolName
                        Write-Verbose "Renamed Pool with ID=$poolId to $poolName"
                    }
                }
            }

            TestScript = {
                $namesOk = $true
                foreach ($pool in Get-StoragePool -IsPrimordial:$false) {
                    $poolName = $pool.FriendlyName
                    $poolId = $pool.UniqueId.Substring(1, 36)
                    $clusterResource = Get-ClusterResource -Cluster $using:ClusterName | Where-Object Id -eq $poolId

                    if ($clusterResource.Name -ne $poolName) {
                        $namesOk = $false
                        Write-Verbose "Pool with ID=${poolId} Name does not match '$poolName'"
                    }
                }
                return $namesOk
            }

            GetScript = {
                return @{ poolNames = foreach ($pool in Get-StoragePool -IsPrimordial:$false) { Write-Output $pool.FriendlyName } }
            }

            PsDscRunAsCredential = $ADCredentials
            DependsOn  = '[Script]S2DPool_Default', '[Script]S2DPool_FCI', '[Script]S2DPool_CorePlatform', '[Script]S2DPool_Archive', '[Script]S2DPool_Backup'
        }

        # Rename Disks' Friendly Names according to naming standards
        Script S2DDisks_FriendlyNames {
            SetScript = {
                foreach ($disk in Get-PhysicalDisk) {
                    $diskName = $disk.FriendlyName
                    $volId = $disk.SerialNumber.Replace('vol', 'vol-').Replace('_00000001.', '')
                    $desiredDiskName = (Get-EC2Tag -Filter @(@{Name = "resource-id"; Value = $volId }, @{Name = "tag:Name"; Value = "*" })).Value

                    if ($desiredDiskName -ne $null -and $diskName -ne $desiredDiskName) {
                        $disk | Set-PhysicalDisk -NewFriendlyName $desiredDiskName
                        Write-Verbose "Volume '$volId' changed friendly name from '$diskName' to '$desiredDiskName'"
                    }
                }
            }

            TestScript = {
                $namesOk = $true
                foreach ($disk in Get-PhysicalDisk) {
                    $diskName = $disk.FriendlyName
                    $volId = $disk.SerialNumber.Replace('vol', 'vol-').Replace('_00000001.', '')
                    $desiredDiskName = (Get-EC2Tag -Filter @(@{Name = "resource-id"; Value = $volId }, @{Name = "tag:Name"; Value = "*" })).Value

                    if ($desiredDiskName -ne $null -and $diskName -ne $desiredDiskName) {
                        Write-Verbose "Volume '$volId' has Name = '$diskName' and the DesiredDiskName = '$desiredDiskName'"
                        $namesOk = $false
                    }
                }

                return $namesOk
            }

            GetScript = {
                return @{diskNames = foreach ($disk in Get-PhysicalDisk) { Write-Output $disk.FriendlyName } }
            }

            # PsDscRunAsCredential = $ADCredentials
            Credential = $ADCredentials
            DependsOn  = '[Script]S2DPool_Default', '[Script]S2DPool_FCI', '[Script]S2DPool_CorePlatform', '[Script]S2DPool_Archive', '[Script]S2DPool_Backup'
        }

    }
}

PrimaryNodeConfig -OutputPath 'C:\SQLClusterDSCConfig\PrimaryNodeConfig' -ConfigurationData $ConfigurationData  -ADCredentials $ADCredentials -SQLSvcAcctCredentials $SQLSvcAcctCredentials
