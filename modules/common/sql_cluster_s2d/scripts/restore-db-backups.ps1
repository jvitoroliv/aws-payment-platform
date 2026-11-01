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
    $SQLLoginCredentialsARN,

    [Parameter(Mandatory = $true)]
    [string]
    $SQLInstanceName,

    [Parameter(Mandatory = $true)]
    [string]
    $SQLClusterNetworkName,

    [Parameter(Mandatory = $true)]
    [string]
    $EncFI,

    [Parameter(Mandatory = $true)]
    [string]
    $Environment,

    [Parameter(Mandatory = $true)]
    [string]
    $SqlBackupsBucket
)

Write-Host "Getting AD Admin creds from Secrets Manager."
$DomainAdminPassword = (Get-SECSecretValue -SecretId $DomainAdminPasswordARN).SecretString
$DomainAdminUser = $NetBiosDomainName + '\' + $DomainAdminUser
$ADCredentials = (New-Object PSCredential($DomainAdminUser, (ConvertTo-SecureString $DomainAdminPassword -AsPlainText -Force)))

Write-Host "Getting SQL login creds from Secrets Manager."
$SQLLoginCredsFromSecretsMgr = ConvertFrom-JSON -InputObject (Get-SECSecretValue -SecretId $SQLLoginCredentialsARN).SecretString
$SQLLoginUser = $SQLLoginCredsFromSecretsMgr.Userid


$BackupRoot = "C:\ClusterStorage\${EncFI}_Backup"
$RestoreRoot = "C:\ClusterStorage\${EncFI}_CoreService\${Environment}\${EncFI}"
$SQLInstance = "${SQLClusterNetworkName}\${SQLInstanceName}"

# placeholders and RestoreScript variants will be unncessary after filegroups are standardized
$dbNamePlaceholder = "{{_DB_NAME_}}"
$filePathPlaceholder = "{{_FILE_PATH_}}"
$rootPathPlaceholder = "{{_ROOT_PATH_}}"

$coreplatformRestoreScript = @"
RESTORE DATABASE [$dbNamePlaceholder] FROM  DISK = N'$filePathPlaceholder'
WITH  FILE = 1
, MOVE N'primary' TO N'$rootPathPlaceholder\Data\Primary.mdf'
, MOVE N'businessData_01' TO N'$rootPathPlaceholder\Data\BusinessData_01.ndf'
, MOVE N'businessData_02' TO N'$rootPathPlaceholder\Data\BusinessData_02.ndf'
, MOVE N'businessData_03' TO N'$rootPathPlaceholder\Data\BusinessData_03.ndf'
, MOVE N'businessIndex_01' TO N'$rootPathPlaceholder\Data\BusinessIndex_01.ndf'
, MOVE N'businessIndex_02' TO N'$rootPathPlaceholder\Data\BusinessIndex_02.ndf'
, MOVE N'businessIndex_03' TO N'$rootPathPlaceholder\Data\BusinessIndex_03.ndf'
, MOVE N'secureData_01' TO N'$rootPathPlaceholder\Data\SecureData_01.ndf'
, MOVE N'secureIndex_01' TO N'$rootPathPlaceholder\Data\SecureIndex_01.ndf'
, MOVE N'validationData_01' TO N'$rootPathPlaceholder\Data\ValidationData_01.ndf'
, MOVE N'validationIndex_01' TO N'$rootPathPlaceholder\Data\ValidationIndex_01.ndf'
, MOVE N'log_01' TO N'$rootPathPlaceholder\Log\Log_01.ldf'
, NOUNLOAD,  REPLACE,  STATS = 5
"@


$dbInfo = @()
if ($EncFI.ToUpper() -eq "SAMPLE_FI")
{
  $dbInfo = @(
    @{
      DatabaseName = "SAMPLE_FI_TS1_CoreService"
      BackupPrefix = "AKUSA_QA_CoreService_backup"
      BackupFilePath = ""
      RestoreRoot = "$RestoreRoot\CoreService"
      RestoreScript = $coreplatformRestoreScript
    },
    @{
      DatabaseName = "SAMPLE_FI_TS1_CDEF"
      BackupPrefix = "CDEF/AKUSA_QA_CDEF_TS1_backup"
      BackupFilePath = ""
      RestoreRoot = "$RestoreRoot\CDEF\TS1"
      RestoreScript = @"
RESTORE DATABASE [$dbNamePlaceholder] FROM  DISK = N'$filePathPlaceholder'
WITH  FILE = 1
, MOVE N'primary' TO N'$rootPathPlaceholder\Data\Primary.mdf'
, MOVE N'businessData_01' TO N'$rootPathPlaceholder\Data\BusinessData_01.ndf'
, MOVE N'businessIndex_01' TO N'$rootPathPlaceholder\Data\BusinessIndex_01.ndf'
, MOVE N'log_01_2DA86550' TO N'$rootPathPlaceholder\Data\log_01_2DA86550.mdf'
, MOVE N'log_01' TO N'$rootPathPlaceholder\Log\Log_01.ldf'
, NOUNLOAD,  REPLACE
"@
    }
  )
}
if ($EncFI.ToUpper() -eq "FINSERV")
{
  $dbInfo = @(
    @{
      DatabaseName = "FINSERV_TS1_CoreService"
      BackupPrefix = "FINSERV_QA_CoreService_backup"
      BackupFilePath = ""
      RestoreRoot = "$RestoreRoot\CoreService"
      RestoreScript = $coreplatformRestoreScript
    },
    @{
      DatabaseName = "FINSERV_TS1_CDEF"
      BackupPrefix = "CDEF/FINSERV_QA_CDEF_TS1NA_backup"
      BackupFilePath = ""
      RestoreRoot = "$RestoreRoot\CDEF\TS1"
      RestoreScript = @"
RESTORE DATABASE [$dbNamePlaceholder] FROM  DISK = N'$filePathPlaceholder'
WITH  FILE = 1
, MOVE N'primary' TO N'$rootPathPlaceholder\Data\Primary.mdf'
, MOVE N'businessData_01' TO N'$rootPathPlaceholder\Data\BusinessData_01.ndf'
, MOVE N'businessIndex_01' TO N'$rootPathPlaceholder\Data\BusinessIndex_01.ndf'
, MOVE N'log_01_5B105CB6' TO N'$rootPathPlaceholder\Data\log_01_5B105CB6.mdf'
, MOVE N'log_01' TO N'$rootPathPlaceholder\Log\Log_01.ldf'
, NOUNLOAD,  REPLACE
"@
    },
    @{
      DatabaseName = "FINSERV_CDEF_TS2NA"
      BackupPrefix = "CDEF/FINSERV_QA_CDEF_TS2NA_backup"
      BackupFilePath = ""
      RestoreRoot = "$RestoreRoot\CDEF\TS2NA"
      RestoreScript = @"
RESTORE DATABASE [$dbNamePlaceholder] FROM  DISK = N'$filePathPlaceholder'
WITH  FILE = 1
, MOVE N'primary' TO N'$rootPathPlaceholder\Data\Primary.mdf'
, MOVE N'businessData_01' TO N'$rootPathPlaceholder\Data\BusinessData_01.ndf'
, MOVE N'businessIndex_01' TO N'$rootPathPlaceholder\Data\BusinessIndex_01.ndf'
, MOVE N'log_01_492572BF' TO N'$rootPathPlaceholder\Data\log_01_492572BF.mdf'
, MOVE N'log_01' TO N'$rootPathPlaceholder\Log\Log_01.ldf'
, NOUNLOAD,  REPLACE
"@
    },
    @{
      DatabaseName = "FINSERV_CDEF_TS2EU"
      BackupPrefix = "CDEF/FINSERV_QA_CDEF_TS2EU_backup"
      BackupFilePath = ""
      RestoreRoot = "$RestoreRoot\CDEF\TS2EU"
      RestoreScript = @"
RESTORE DATABASE [$dbNamePlaceholder] FROM  DISK = N'$filePathPlaceholder'
WITH  FILE = 1
, MOVE N'primary' TO N'$rootPathPlaceholder\Data\Primary.mdf'
, MOVE N'businessData_01' TO N'$rootPathPlaceholder\Data\BusinessData_01.ndf'
, MOVE N'businessIndex_01' TO N'$rootPathPlaceholder\Data\BusinessIndex_01.ndf'
, MOVE N'log_01_41B3CEBA' TO N'$rootPathPlaceholder\Data\log_01_41B3CEBA.mdf'
, MOVE N'log_01' TO N'$rootPathPlaceholder\Log\Log_01.ldf'
, NOUNLOAD,  REPLACE
"@
    },
    @{
      DatabaseName = "FINSERV_CDEF_TS2AP"
      BackupPrefix = "CDEF/FINSERV_QA_CDEF_TS2AP_backup"
      BackupFilePath = ""
      RestoreRoot = "$RestoreRoot\CDEF\TS2AP"
      RestoreScript = @"
RESTORE DATABASE [$dbNamePlaceholder] FROM  DISK = N'$filePathPlaceholder'
WITH  FILE = 1
, MOVE N'primary' TO N'$rootPathPlaceholder\Data\Primary.mdf'
, MOVE N'businessData_01' TO N'$rootPathPlaceholder\Data\BusinessData_01.ndf'
, MOVE N'businessIndex_01' TO N'$rootPathPlaceholder\Data\BusinessIndex_01.ndf'
, MOVE N'log_01_16A0759' TO N'$rootPathPlaceholder\Data\log_01_16A0759.mdf'
, MOVE N'log_01' TO N'$rootPathPlaceholder\Log\Log_01.ldf'
, NOUNLOAD,  REPLACE
"@
    },
    @{
      DatabaseName = "FINSERV_CDEF_MOCK_SERVICE"
      BackupPrefix = "CDEF/FINSERV_QA_CDEF_MOCK_SERVICE_backup"
      BackupFilePath = ""
      RestoreRoot = "$RestoreRoot\CDEF\MOCK_SERVICE"
      RestoreScript = @"
RESTORE DATABASE [$dbNamePlaceholder] FROM  DISK = N'$filePathPlaceholder'
WITH  FILE = 1
, MOVE N'primary' TO N'$rootPathPlaceholder\Data\Primary.mdf'
, MOVE N'businessData_01' TO N'$rootPathPlaceholder\Data\BusinessData_01.ndf'
, MOVE N'businessIndex_01' TO N'$rootPathPlaceholder\Data\BusinessIndex_01.ndf'
, MOVE N'log_01' TO N'$rootPathPlaceholder\Log\Log_01.ldf'
, NOUNLOAD,  REPLACE
"@
    }
  )
}












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

Configuration DbRestore {
  [CmdletBinding()]
  param (
    [PSCredential] $ADCredentials,
    [string] $SQLLoginUser,
    [string] $SQLInstance,
    [string] $SqlBackupsBucket,
    [object[]] $DbInfo,
    [string] $BackupRoot,
    [string] $RestoreRoot,
    [string] $dbNamePlaceholder,
    [string] $filePathPlaceholder,
    [string] $rootPathPlaceholder
  )

  Import-Module -Name PSDesiredStateConfiguration
  Import-DscResource -Module PSDesiredStateConfiguration

  node 'localhost' {

    Script Run {
      SetScript = {
          
          foreach ($info in $using:DbInfo)
          {
              Write-Host "Finding latest backup for $($info.DatabaseName) from $using:SqlBackupsBucket bucket."
              $object = Get-S3Object -BucketName $using:SqlBackupsBucket -KeyPrefix $info.BackupPrefix | sort LastModified, key -Descending | select -First 1
              $key = $object.Key
              $lastModified = $object.LastModified
              #$filename = ($key -split "/")[-1]
              $outfile = "$using:BackupRoot\$($key.Replace("/", "\"))"
              $info.BackupFilePath = $outfile

              
              if ((-Not (Test-Path $outfile -PathType Leaf)) -or (($lastModified -gt (Get-Item $outfile).LastWriteTime) -and (Test-Path $outfile -PathType Leaf)))
              {
                  Write-Host "Downloading $key from $using:SqlBackupsBucket bucket."
                  Read-S3Object -BucketName $using:SqlBackupsBucket -Key $key -File $outfile -Verbose
                  Write-Host "Download complete."
              }
              else
              {
                  Write-Host "Looks like $key has already been downloaded to $outfile"
              }
          }


          foreach ($info in $using:DbInfo)
          {
              $dbName = $info.DatabaseName
              $filePath = $info.BackupFilePath
              $rootPath = $info.RestoreRoot
              $restoreScript = $info.RestoreScript.Replace("$using:dbNamePlaceholder", "$dbName").Replace("$using:filePathPlaceholder", "$filePath").Replace("$using:rootPathPlaceholder", "$rootPath")

              md -Force "${rootPath}\Data"
              md -Force "${rootPath}\Log"

              $restoreScript = $restoreScript.Replace("`r`n", " ")

              Write-Host "Restoring database $dbName from $filePath"
              Invoke-Sqlcmd -Query "$restoreScript" -ServerInstance $using:SQLInstance -Database "master" -QueryTimeout 0


              # TDOO: remove after completing AD integration
              $userScript1 = "CREATE USER [$using:SQLLoginUser] FOR LOGIN [$using:SQLLoginUser]"
              $userScript2 = "ALTER USER [$using:SQLLoginUser] WITH DEFAULT_SCHEMA=[dbo]"
              $userScript3 = "ALTER ROLE [db_owner] ADD MEMBER [$using:SQLLoginUser]"

              Write-Host "Adding user $using:SQLLoginUser to database $dbName"
              Invoke-Sqlcmd -Query "$userScript1" -ServerInstance $using:SQLInstance -Database "$dbName" -QueryTimeout 0
              Invoke-Sqlcmd -Query "$userScript2" -ServerInstance $using:SQLInstance -Database "$dbName" -QueryTimeout 0
              Invoke-Sqlcmd -Query "$userScript3" -ServerInstance $using:SQLInstance -Database "$dbName" -QueryTimeout 0
          }




          $encDbInfo = $using:DbInfo | where {$_.DatabaseName.EndsWith("_CoreService")}
          $dbName = $encDbInfo.DatabaseName

          $sqlclrScripts = @(
              "sp_configure 'show advanced options', 1"
              "RECONFIGURE",
              "sp_configure 'clr_enabled', 1"
              "RECONFIGURE",
              "sp_configure",
              @"
DECLARE @clrName nvarchar(4000);
DECLARE @asmId int;
DECLARE @asmBin varbinary(max);
DECLARE @hash varbinary(64);

select @clrName = clr_name, @asmId = assembly_id from [$dbName].sys.assemblies where name = 'SqlClrCrypto';
select @asmBin = content from [$dbName].sys.assembly_files where assembly_id = @asmId;

SELECT @hash = HASHBYTES('SHA2_512', @asmBin);
EXEC sys.sp_add_trusted_assembly @hash = @hash, @description = @clrName;
"@,
              @"
DECLARE @asmId int;
DECLARE @asmBin varbinary(max);

select @asmId = assembly_id from [$dbName].sys.assemblies where name = 'SqlClrCrypto';
select @asmBin = content from [$dbName].sys.assembly_files where assembly_id = @asmId;

CREATE ASSEMBLY [SqlClrCrypto]
FROM @asmBin
WITH PERMISSION_SET = EXTERNAL_ACCESS
"@,
              "CREATE ASYMMETRIC KEY SQLCLRKey FROM ASSEMBLY [SqlClrCrypto]",
              "CREATE LOGIN SQLCLRLogin FROM ASYMMETRIC KEY SQLCLRKey",
              "GRANT EXTERNAL ACCESS ASSEMBLY TO SQLCLRLogin", # pre SQL2017
              "GRANT UNSAFE ASSEMBLY TO SQLCLRLogin", # SQL2017 and later
              "DROP ASSEMBLY [SqlClrCrypto]",
              "GRANT EXTERNAL ACCESS ASSEMBLY TO [$using:SQLLoginUser]"
          )

          Write-Host "Running sqlclr scripts for database $dbName"
          foreach ($script in $sqlclrScripts)
          {
              Write-Host "$script"
              Invoke-Sqlcmd -Query "$script" -ServerInstance $using:SQLInstance -Database "master" -QueryTimeout 0
          }

      }

      TestScript = {
          $encDbInfo = $using:DbInfo | where {$_.DatabaseName.EndsWith("_CoreService")}
          $query = "select name from sys.sysdatabases where name = '$($encDbInfo.DatabaseName)'"
          
          $queryResult = Invoke-Sqlcmd -Query $query -ServerInstance "$using:SQLInstance"

          $result = $false
          if ($queryResult -ne $null -and $queryResult['name'] -eq "$encDbInfo.DatabaseName")
          {
              $result = $true
          }

          return $result
      }

      GetScript = {
          $encDbInfo = $using:DbInfo | where {$_.DatabaseName.EndsWith("_CoreService")}
          $query = "select name from sys.sysdatabases where name = '$($encDbInfo.DatabaseName)'"

          $queryResult = Invoke-Sqlcmd -Query $query -ServerInstance "$using:SQLInstance"

          $result = "Does not exist"
          if ($queryResult -ne $null -and $queryResult['name'] -eq "$encDbInfo.DatabaseName")
          {
            $result = "Exists"
          }

          return @{Result = $result }
      }

      PsDscRunAsCredential = $ADCredentials
    }
  }
}

DbRestore -OutputPath 'C:\SQLClusterDSCConfig\DbRestore' -ConfigurationData $ConfigurationData -ADCredentials $ADCredentials -SQLLoginUser $SQLLoginUser -SQLInstance $SQLInstance -SqlBackupsBucket $SqlBackupsBucket -DbInfo $dbInfo -BackupRoot $BackupRoot -RestoreRoot $RestoreRoot -dbNamePlaceholder $dbNamePlaceholder -filePathPlaceholder $filePathPlaceholder -rootPathPlaceholder $rootPathPlaceholder


