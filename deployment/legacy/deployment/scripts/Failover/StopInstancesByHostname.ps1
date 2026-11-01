Param(
    [string]$regionabbrev = "ue1",
    [string]$environment,
    [string]$region = "us-east-1",
    [string]$instanceList
)

$environment = $environment.ToLower()

Write-Host "Stopping $region Instances"
foreach($hostName in $instanceList.Split(',')) {
    $instances = Get-EC2Instance -Region $region -Filter @{Name="tag:Hostname";Values="$hostName"},@{Name="instance-state-name";Value="running"}
    
    if ($instances) {
        foreach($instance in $instances.Instances) {
            Write-Host "Stopping" $hostName ":" $instance.InstanceId
            Stop-EC2Instance -region $region -InstanceId $instance.InstanceId
        }
    }
}

Write-Host "Done!"