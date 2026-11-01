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
    $SQLLoginCredentialsARN,

    [Parameter(Mandatory = $true)]
    [string]
    $SQLInstanceName,

    [Parameter(Mandatory = $true)]
    [string]
    $SQLClusterIP,

    [Parameter(Mandatory = $true)]
    [string]
    $Node2SQLIP,
    
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

# Get SQL login user & password from Secrets Manager:
$SQLLoginCredsFromSecretsMgr = ConvertFrom-JSON -InputObject (Get-SECSecretValue -SecretId $SQLLoginCredentialsARN).SecretString
$SQLLoginUser = $SQLLoginCredsFromSecretsMgr.Userid
$SQLLoginPassword = $SQLLoginCredsFromSecretsMgr.Password
# Create a PSCredential object of the SQL login creds:
$SQLLoginCredentials = (New-Object PSCredential($SQLLoginUser, (ConvertTo-SecureString $SQLLoginPassword -AsPlainText -Force)))


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

Configuration SQLInstall {
    [CmdletBinding()]
    param (
        [PSCredential] $ADCredentials,
        [PSCredential] $SQLSvcAcctCredentials,
        [PSCredential] $SQLLoginCredentials,
        [string] $SQLSvcAcctUserAD,
        [string] $SQLInstanceName,
        [string] $SQLClusterNetworkName,
        [string] $SQLClusterIP,
        [string] $Node2SQLIP,
        [string] $EncFI
    )

    Import-Module -Name PSDesiredStateConfiguration
    Import-Module -Name xSmbShare
    Import-Module -Name SqlServerDsc

    Import-DscResource -Module PSDesiredStateConfiguration
    Import-DscResource -Module xSmbShare
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

        SqlServerNetwork 'ChangeTcpIpOnDefaultInstance'
        {
            InstanceName         = $SQLInstanceName
            ProtocolName         = 'Tcp'
            IsEnabled            = $true
            TCPDynamicPort       = $false
            TCPPort              = 1433
            RestartService       = $true
            PsDscRunAsCredential = $ADCredentials
        }

        SqlSetup 'InstallPrimaryInstance' {
            Action                     = 'InstallFailoverCluster'
            ForceReboot                = $false
            UpdateEnabled              = 'False'
            SourcePath                 = 'C:\SQLClusterDSCConfig\SQLMediaExpanded'

            InstanceName               = $SQLInstanceName
            Features                   = 'SQLENGINE,Replication,FullText,DQ'

            InstallSharedDir           = 'C:\Program Files\Microsoft SQL Server'
            InstallSharedWOWDir        = 'C:\Program Files (x86)\Microsoft SQL Server'
            InstanceDir                = 'C:\Program Files\Microsoft SQL Server'

            SQLCollation               = 'SQL_Latin1_General_CP1_CI_AS'

            SQLSvcAccount              = $SQLSvcAcctCredentials
            AgtSvcAccount              = $SQLSvcAcctCredentials
            SQLSysAdminAccounts        = $DomainAdminUser  #TODO: add db admin AD group

            #TODO: remove after gMSA support for ECS is available
            SecurityMode               = "SQL"
            SAPwd                      = $SQLLoginCredentials

            # Using Cluster Shared Volume
            InstallSQLDataDir          = "C:\ClusterStorage\${EncFI}_FCI"

            FailoverClusterNetworkName = $SQLClusterNetworkName
            FailoverClusterIpAddress   = $SQLClusterIP

            PsDscRunAsCredential       = $ADCredentials

            DependsOn                  = '[WindowsFeature]NetFramework35', '[WindowsFeature]NetFramework45', '[SqlServerNetwork]ChangeTcpIpOnDefaultInstance'
        }

        # Note: This is currently hard-coded to 3 total nodes.
        Script AddSQLIPDependencies {
            SetScript = {
                $SQLInstanceName = $using:SQLInstanceName
                $SQLClusterNetworkName = $using:SQLClusterNetworkName
                $Node2SQLIP = $using:Node2SQLIP

                # Rename the 1st SQL cluster resource IP to 'SQLIP1':
                if ( -not( Get-ClusterResource | Where-Object { $_.Name -eq "SQLIP1" } )) { 
                    (Get-ClusterResource | Where-Object { ($_.ResourceType -eq "IP address") -and ($_.Name -match "${SQLClusterNetworkName}") } ).Name = "SQLIP1"
                }

                # Add IPs on other 2 nodes:
                if ( -not( Get-ClusterResource | Where-Object { $_.Name -eq "SQLIP2" } )) {
                    Write-Verbose -Message "Adding an IP Address (Node #2) resource to the Cluster Network resource for SQL Server."
                    Add-ClusterResource -Name "SQLIP2" -ResourceType "IP Address" -Group "SQL Server (${SQLInstanceName})" -ErrorAction SilentlyContinue
                }
                Get-ClusterResource -Name "SQLIP2" | Set-ClusterParameter -Multiple @{"Address" = "${Node2SQLIP}"; "SubnetMask" = "255.255.255.0"; "EnableDhcp" = "0" } -ErrorAction SilentlyContinue

                # Set up the IP Dependency:
                Write-Verbose -Message "Set up the IP addresses as OR dependencies on the Cluster Network resource for SQL Server."
                $SQLClusterNetworkNameObj = get-ClusterResource | Where-Object { ($_.ResourceType -eq "Network Name") -and ($_.OwnerGroup -match "SQL") }
                Set-ClusterResourceDependency -InputObject $SQLClusterNetworkNameObj  -Dependency "[SQLIP1] or [SQLIP2]"
            }

            TestScript = {
                $Node2SQLIP = $using:Node2SQLIP
                $depOK = $true
                try {
                    # Tests whether there are 3 IP dependencies
                    $SQLClusterNetworkNameObj = get-ClusterResource | Where-Object { ($_.ResourceType -eq "Network Name") -and ($_.OwnerGroup -match "SQL") }
                    $dep = (Get-ClusterResourceDependency -cluster $using:ClusterName -InputObject $SQLClusterNetworkNameObj -ErrorAction SilentlyContinue)."DependencyExpression"
                    $separator = " or "
                    if ( ($dep -split $separator).count -ne 3 ) { $depOK = $false }

                    # Do the IP Address resources exist?
                    # And if they do, check if the IPs are assigned to the IP Address resources:
                    if ( -not( Get-ClusterResource | Where-Object { $_.Name -eq "SQLIP2" } )) { 
                        Write-Verbose -Message "SQLIP2 IP Address resource does not exist."
                        $depOK = $false
                    }
                    elseif ( -not((Get-ClusterResource -Name "SQLIP2" | Get-ClusterParameter -Name Address).Value -eq $Node2SQLIP) ) {
                        Write-Verbose -Message "SQLIP2 does not have its IP Address set correctly."
                        $depOK = $false
                    }

                    Write-Verbose -Message "SQL Cluster Network Name's IP Dependency is currently set to: $dep"
                    return $depOK
                }
                catch { 
                    return $false
                }
            }

            GetScript = {
                $SQLClusterNetworkNameObj = get-ClusterResource | Where-Object { ($_.ResourceType -eq "Network Name") -and ($_.OwnerGroup -match "SQL") }
                return @{Dependency = Get-ClusterResourceDependency -Cluster $using:ClusterName -InputObject $SQLClusterNetworkNameObj -ErrorAction SilentlyContinue}
            }

            PsDscRunAsCredential = $ADCredentials
            DependsOn  = '[SqlSetup]InstallPrimaryInstance'
        }

        Script SetDNSParams {
            SetScript = {
                $SQLClusterNetworkName = $using:SQLClusterNetworkName

                # Configure the SQL Cluster Network Name so it updates DNS A record every 5 mins
                Write-Verbose -Message "Configuring the Cluster Network resource for SQL Server's DNS params with a TTYL of 300 seconds (5 mins)."
                Get-ClusterResource | Where-Object { $_.Name -match "${SQLClusterNetworkName}" } | Set-ClusterParameter HostRecordTTL 300
                # Next setting disabled per Tyler Barriger:
                # This is to maintain the default where all SQL Server instances to register in DNS.
                # Write-Verbose -Message "Configuring the Cluster Network resource for SQL Server's DNS params so that only 1 A record is maintained in AD/DNS."
                # Get-ClusterResource | Where-Object { $_.Name -match "${SQLClusterNetworkName}" } | Set-ClusterParameter RegisterAllProvidersIp 0# Restart the Cluster Network resource for the settings to take effect:
                Get-ClusterResource | Where-Object { $_.Name -match "${SQLClusterNetworkName}" } | Stop-ClusterResource
                Get-ClusterResource | Where-Object { $_.Name -match "${SQLClusterNetworkName}" } | Start-ClusterResource

                #TODO: remove
                Start-Sleep -s 60
            }

            TestScript = { 
                return $false
            }

            GetScript = {
                $SQLClusterNetworkName = $using:SQLClusterNetworkName
                return @{NetworkNameParams = Get-ClusterResource | Where-Object { $_.Name -match "${SQLClusterNetworkName}" } | Get-ClusterParameter }
            }

            PsDscRunAsCredential = $ADCredentials
            DependsOn  = '[Script]AddSQLIPDependencies'
        }

        Script SQLAgentServiceOnline {
            SetScript = {
                $SQLInstanceName = $using:SQLInstanceName
                $resourceName = "SQL Server Agent ($SQLInstanceName)"

                Write-Verbose -Message "Checking state of $resourceName."
                $state = (Get-ClusterResource | where Name -eq $resourceName | select State).State
                Write-Verbose -Message "Cluster Resource $resourceName is $state."

                If ($state -ne "Online") {
                    Start-ClusterResource $resourceName
                }
            }

            TestScript = {
                $SQLInstanceName = $using:SQLInstanceName
                $resourceName = "SQL Server Agent ($SQLInstanceName)"
                $state = (Get-ClusterResource | where Name -eq $resourceName | select State).State

                $result = $state -eq "Online"
                return $result
            }

            GetScript = {
                $SQLInstanceName = $using:SQLInstanceName
                $resourceName = "SQL Server Agent ($SQLInstanceName)"
                $state = (Get-ClusterResource | where Name -eq $resourceName | select State).State

                return @{Result = "$state" }
            }

            PsDscRunAsCredential = $ADCredentials
            DependsOn  = '[Script]SetDNSParams'
        }

        Script AddSqlLogin {
            SetScript = {
                $SQLInstance = "$using:SQLClusterNetworkName\$using:SQLInstanceName"
                $query = "select name from sys.syslogins where name = '$using:SQLLoginUser'"
                
                $queryResult = Invoke-Sqlcmd -Query $query -ServerInstance "$SQLInstance"
                if ($queryResult -eq $null)
                {
                    $query = "CREATE LOGIN [coreplatformappuser] WITH PASSWORD=N'$using:SQLLoginPassword', DEFAULT_DATABASE=[master], DEFAULT_LANGUAGE=[us_english], CHECK_EXPIRATION=OFF, CHECK_POLICY=OFF"
                    Invoke-Sqlcmd -Query $query -ServerInstance "$SQLInstance"
                }

            }

            TestScript = {
                $SQLInstance = "$using:SQLClusterNetworkName\$using:SQLInstanceName"
                $query = "select name from sys.syslogins where name = '$using:SQLLoginUser'"
                
                $queryResult = Invoke-Sqlcmd -Query $query -ServerInstance "$SQLInstance"

                $result = $false
                if ($queryResult -ne $null -and $queryResult['name'] -eq "$using:SQLLoginUser")
                {
                    $result = $true
                }

                return $result
            }

            GetScript = {
                $SQLInstance = "$using:SQLClusterNetworkName\$using:SQLInstanceName"
                $query = "select name from sys.syslogins where name = '$using:SQLLoginUser'"
                
                $queryResult = Invoke-Sqlcmd -Query $query -ServerInstance "$SQLInstance"

                $result = "Does not exist"
                if ($queryResult -ne $null -and $queryResult['name'] -eq "$using:SQLLoginUser")
                {
                    $result = "Exists"
                }
                return @{Result = $result }
            }

            PsDscRunAsCredential = $ADCredentials
            DependsOn  = '[Script]SQLAgentServiceOnline'
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
            DependsOn  = '[Script]AddSqlLogin'
        }

        # The SqlServerLogin calls below error out when running via SSM, but succeed when running the DSC locally as admin in elevated PS
        # Error:
        # PowerShell DSC resource MSFT_SqlServerLogin failed to execute Test-TargetResource functionality with error message: 
        # System.InvalidOperationException: Failed to connect to SQL instance 'SQLNODE001\SAMPLE_FI_DEV_FCI'. (SQLCOMMON0019) 
        # ---> System.Management.Automation.MethodInvocationException: Exception calling "Connect" with "0" argument(s): "Failed to connect to server SQLNODE001\SAMPLE_FI_DEV_FCI."
        # ---> Microsoft.SqlServer.Management.Common.ConnectionFailureException: Failed to connect to server SQLNODE001\SAMPLE_FI_DEV_FCI. 
        # ---> System.Data.SqlClient.SqlException: A network-related or instance-specific error occurred while establishing a connection to SQL Server.
        #      The server was not found or was not accessible. Verify that the instance name is correct and that SQL Server is configured to allow remote connections.
        #      (provider: Named Pipes Provider, error: 40 - Could not open a connection to SQL Server) 
        # ---> System.ComponentModel.Win32Exception: The system cannot find the file specified
        #    --- End of inner exception stack trace ---
        #    at System.Data.SqlClient.SqlInternalConnectionTds..ctor(DbConnectionPoolIdentity identity, SqlConnectionString connectionOptions, SqlCredential credential, Object providerInfo, String newPassword, SecureString newSecurePassword, Boolean redirectedUserInstance, SqlConnectionString userConnectionOptions, SessionData reconnectSessionData, DbConnectionPool pool, String accessToken, Boolean applyTransientFaultHandling, SqlAuthenticationProviderManager sqlAuthProviderManager)
        #    at System.Data.SqlClient.SqlConnectionFactory.CreateConnection(DbConnectionOptions options, DbConnectionPoolKey poolKey, Object poolGroupProviderInfo, DbConnectionPool pool, DbConnection owningConnection, DbConnectionOptions userOptions)
        #    at System.Data.ProviderBase.DbConnectionFactory.CreatePooledConnection(DbConnectionPool pool, DbConnection owningObject, DbConnectionOptions options, DbConnectionPoolKey poolKey, DbConnectionOptions userOptions)
        #    at System.Data.ProviderBase.DbConnectionPool.CreateObject(DbConnection owningObject, DbConnectionOptions userOptions, DbConnectionInternal oldConnection)
        #    at System.Data.ProviderBase.DbConnectionPool.UserCreateRequest(DbConnection owningObject, DbConnectionOptions userOptions, DbConnectionInternal oldConnection)
        #    at System.Data.ProviderBase.DbConnectionPool.TryGetConnection(DbConnection owningObject, UInt32 waitForMultipleObjectsTimeout, Boolean allowCreate, Boolean onlyOneCheckConnection, DbConnectionOptions userOptions, DbConnectionInternal& connection)
        #    at System.Data.ProviderBase.DbConnectionPool.TryGetConnection(DbConnection owningObject, TaskCompletionSource`1 retry, DbConnectionOptions userOptions, DbConnectionInternal& connection)
        #    at System.Data.ProviderBase.DbConnectionFactory.TryGetConnection(DbConnection owningConnection, TaskCompletionSource`1 retry, DbConnectionOptions userOptions, DbConnectionInternal oldConnection, DbConnectionInternal& connection)
        #    at System.Data.ProviderBase.DbConnectionInternal.TryOpenConnectionInternal(DbConnection outerConnection, DbConnectionFactory connectionFactory, TaskCompletionSource`1 retry, DbConnectionOptions userOptions)
        #    at System.Data.SqlClient.SqlConnection.TryOpenInner(TaskCompletionSource`1 retry)
        #    at System.Data.SqlClient.SqlConnection.TryOpen(TaskCompletionSource`1 retry)
        #    at System.Data.SqlClient.SqlConnection.Open()
        #    at Microsoft.SqlServer.Management.Common.ConnectionManager.InternalConnect(WindowsIdentity impersonatedIdentity)
        #    at Microsoft.SqlServer.Management.Common.ConnectionManager.Connect()
        #    --- End of inner exception stack trace ---
        #    at Microsoft.SqlServer.Management.Common.ConnectionManager.Connect()
        #    at CallSite.Target(Closure , CallSite , Object )
        #    --- End of inner exception stack trace ---
        #    at System.Management.Automation.ExceptionHandlingOps.CheckActionPreference(FunctionContext funcContext, Exception exception)
        #    at System.Management.Automation.Interpreter.ActionCallInstruction`2.Run(InterpretedFrame frame)
        #    at System.Management.Automation.Interpreter.EnterTryCatchFinallyInstruction.Run(InterpretedFrame frame)
        #    at System.Management.Automation.Interpreter.EnterTryCatchFinallyInstruction.Run(InterpretedFrame frame)
        #    --- End of inner exception stack trace --- 
        #     + CategoryInfo          : InvalidOperation: (:) [], CimException
        #     + FullyQualifiedErrorId : ProviderOperationExecutionFailure
        #     + PSComputerName        : localhost

        # SqlServerLogin 'Test_AddWindowsUser' {
        #     Ensure               = 'Present'
        #     Name                 = 'dev\CorePlatformAppuser'
        #     LoginType            = 'WindowsUser'
        #     ServerName           = $SQLClusterNetworkName
        #     InstanceName         = $SQLInstanceName
        #     PsDscRunAsCredential = $ADCredentials
        #     DependsOn            = '[Script]SetDNSParams'
        # }

        # #TODO: remove after gMSA support for ECS is available
        # SqlServerLogin 'AddSqlLogin' {
        #     Ensure                         = 'Present'
        #     Name                           = $SQLLoginUser
        #     LoginType                      = 'SqlLogin'
        #     ServerName                     = $SQLClusterNetworkName
        #     InstanceName                   = $SQLInstanceName
        #     LoginCredential                = $SQLLoginCredentials
        #     LoginMustChangePassword        = $false
        #     LoginPasswordExpirationEnabled = $false
        #     LoginPasswordPolicyEnforced    = $false
        #     PsDscRunAsCredential           = $ADCredentials
        #     DependsOn                      = '[SqlServerLogin]Test_AddWindowsUser'
        # }
    }
}

SQLInstall -OutputPath 'C:\SQLClusterDSCConfig\SQLInstall' -ConfigurationData $ConfigurationData -ADCredentials $ADCredentials -SQLSvcAcctCredentials $SQLSvcAcctCredentials -SQLLoginCredentials $SQLLoginCredentials -SQLSvcAcctUserAD $SQLSvcAcctUserAD -SQLInstanceName $SQLInstanceName -SQLClusterNetworkName $SQLClusterNetworkName -SQLClusterIP $SQLClusterIP -Node2SQLIP $Node2SQLIP -EncFI $EncFI
