Param(
    [string]$regionabbrev = "uw2",
    [string]$region = "AWS-USWEST2",
    [string]$environment,
    [string]$fis
)

$fis = $fis.ToLower()
$environment = $environment.ToLower()

foreach($fi in $fis.Split(',')) {
    $dbName = ""
    switch($fi) {
        "finserv"  { $dbName = "FINSERV_TS1_CorePlatform" }
        "clientbank" { $dbName = "ClientBank_CoreService" }
    }
    
    $cxnString = "Server=$fi-db.coreplatform$environment.$regionabbrev.finservglobal.example.com;Database=$dbName;Connection Timeout=30;Integrated Security=SSPI"

    Write-Host "Connect to database"
    $cxn = New-Object System.Data.SqlClient.SqlConnection($cxnString)
    $cxn.Open()
    $query = "UPDATE ConfigurationSetting SET SettingValue = '$region' WHERE SettingName = 'Location'"
    $cmd = New-Object System.Data.SqlClient.SqlCommand($query, $cxn)
    $cmd.CommandTimeout = 120
    Write-Host "Update Location"
    $cmd.ExecuteNonQuery() | Out-Null
    Write-Host "--Done"

    $query = "EXEC ConfigureCoreServiceForEnvironment"
    $cmd = New-Object System.Data.SqlClient.SqlCommand($query, $cxn)
    $cmd.CommandTimeout = 600
    Write-Host "ConfigureCoreServiceForEnvironment"
    $cmd.ExecuteNonQuery() | Out-Null
    Write-Host "--Done"

    $cxn.Close()
    Write-Host "Done!"
}