Param(
    [string]$regionabbrev = "ue1",
    [string]$environment,
    [string]$region = "us-east-1",
    [string]$instanceList
)

$environment = $environment.ToLower()

Write-Host "Working on $region Instances"
Write-Host ""
foreach($instanceName in $instanceList.Split(',')) {
    $instances = Get-EC2Instance -Region $region -Filter @{Name="tag:Hostname";Values="$instanceName"}
    
    if ($instances) {
        foreach($instance in $instances.Instances) {
            Write-Host $instanceName ":" $instance.InstanceId

            $state = Get-EC2InstanceStatus -InstanceId $instance.InstanceId -IncludeAllInstance $true
            Write-Host "Status:" $state.InstanceState.Name

            if (($state.InstanceState.Name -ne "terminated") -and ($state.InstanceState.Name -ne "shutting-down")) {
                Write-Host "  --Changing Termination Protection"
                Edit-EC2InstanceAttribute -InstanceId $instance.InstanceId -DisableApiTermination $false

                Write-Host "  --Terminating"
                Remove-EC2Instance -region $region -InstanceId $instance.InstanceId -Force
            }
            Write-Host ""
        }
    }
    else {
        Write-Host $instanceName "not found"
		Write-Host ""
    }
}

Write-Host "Done!"