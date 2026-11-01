Param(
    [string]$regionabbrev = "ue1",
    [string]$environment,
    [string]$region = "us-east-1",
    [string]$asgType,
    [string]$fis
)

$environment = $environment.ToLower()
$fis = $fis.ToLower()
$asgType = $asgType.ToLower()

foreach($fi in $fis.Split(',')) {
    Write-Host "Suspending $region $asgType ASG policies for $fi"
    Suspend-ASProcess -region $region -AutoScalingGroupName $regionabbrev-cpt-enc-$fi-$environment-$asgType-asg -ScalingProcess "Launch","Terminate","HealthCheck","ReplaceUnhealthy"

    Write-Host "Stopping $regionabbrev instances in WinSvc ASG"
    foreach($instance in (Get-ASAutoScalingGroup -region $region -AutoScalingGroupName $regionabbrev-cpt-enc-$fi-$environment-$asgType-asg).Instances) {
        $state = Get-EC2InstanceStatus -InstanceId $instance.InstanceId -IncludeAllInstance $true
        if ($state.InstanceState.Name.Value -eq "running") {
            Stop-EC2Instance -region $region -InstanceId $instance.InstanceId
        }
    }
}

Write-Host "Done!"