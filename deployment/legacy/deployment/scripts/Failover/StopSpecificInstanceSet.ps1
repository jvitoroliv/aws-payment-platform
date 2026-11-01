Param(
    [string]$regionabbrev = "ue1",
    [string]$environment,
    [string]$region = "us-east-1",
    [string]$batchInstances,
    [string]$ftpInstances,
    [string]$fis
)

$environment = $environment.ToLower()
$fis = $fis.ToLower()

Write-Host "Stopping $region Instances"
foreach($instance in $batchInstances.Split(',')) {
    $instances = Get-EC2Instance -Region $region -Filter @{Name="tag:Hostname";Values="$instance"},@{Name="instance-state-name";Value="running"}
    
    if ($instances) {
        Write-Host $instance ": " $instances.Instances[0].InstanceId
        Stop-EC2Instance -region $region -InstanceId $instances.Instances[0].InstanceId
    }
}
foreach($instance in $ftpInstances.Split(',')) {
    $instances = Get-EC2Instance -Region $region -Filter @{Name="tag:Hostname";Values="$instance"},@{Name="instance-state-name";Value="running"}

    if ($instances) {
        Write-Host $instance ":" $instances.Instances[0].InstanceId
        Stop-EC2Instance -region $region -InstanceId $instances.Instances[0].InstanceId
    }
}

foreach($fi in $fis.Split(',')) {
    Write-Host "Suspending $region WinSvc ASG policies for $fi"
    Suspend-ASProcess -region $region -AutoScalingGroupName $regionabbrev-cpt-enc-$fi-$environment-winsvc-asg -ScalingProcess "Launch","Terminate","HealthCheck","ReplaceUnhealthy"

    Write-Host "Stopping $regionabbrev instances in WinSvc ASG"
    foreach($instance in (Get-ASAutoScalingGroup -region $region -AutoScalingGroupName $regionabbrev-cpt-enc-$fi-$environment-winsvc-asg).Instances) {
        Stop-EC2Instance -region $region -InstanceId $instance.InstanceId
    }
}

Write-Host "Done!"