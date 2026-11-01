<#
.SYNOPSIS
    Scales up the list of ASG's passed to this script
.DESCRIPTION
    This script takes in list of objects that would specify the component, min and max capacity for the component and scale it up accordingly
    The ASG name would be constructed from the parameters passed to the script ($regionabbrev-cpt-enc-$fi-$environment-$component-asg)
    If the component is shared then the fi parameter could be "shrd"
    This script presumes we are doing this increase in DR accounts, which is uw2 region.
.INPUTS
    [System.String] environment
    [System.String] fi
    [System.Collections.Hashtable []] configs
.EXAMPLE
    ./IncreaseASGCapacityNew.ps1 -config @{"component"="www";"min"=1;"max"=1},@{"component"="svc";"min"=2;"max"=2} -fi abc -environment uat
#>

Param(
    
    [Parameter(Mandatory=$True)]  
    [string] $environment,
    [Parameter(Mandatory=$True)]  
    [string]$fi,
    [Parameter(Mandatory=$True)]  
    [hashtable []]$configs
)

[int]$maxtries = 1000
[string]$regionabbrev = "ue1"

$fi = $fi.ToLower()
$environment = $environment.ToLower()

Write-Host "Region abbrev    = $regionabbrev"
Write-Host "FI               = $fi"
Write-Host "Environment      = $environment"
Write-Host "================================================================================"

function ScaleUp {
    param (
        [string]$asgName,
        [int]$min,
        [int]$max
        )

    Write-Host "Scaling up: $asgName to Min: $min, Max: $max"
    Update-ASAutoScalingGroup -AutoScalingGroupName $asgName -MinSize $min -MaxSize $max -DesiredCapacity $min
}

foreach ($config in $configs) {
    if (!$config.Contains("component") -or !$config.Contains("min")  -or !$config.Contains("max")) {
        Throw "The config object should have specified 'component', 'min', 'max'"
    }
    $component = $config["component"]
    Scaleup -asgName "$regionabbrev-cpt-enc-$fi-$environment-$component-asg" -min $config["min"] -max $config["max"]
}

$tries = 0
while ($tries -lt $maxTries) {
    Start-Sleep -Seconds 10
    Write-Host "================================================================================"

    # Check status of all asgs
    $asgsPending = 0
    $asgsCompleted = 0
    foreach($config in $configs) {
        $component = $config["component"]
        $asgName = "$regionabbrev-cpt-enc-$fi-$environment-$component-asg"
        $instances = (Get-ASAutoScalingGroup -AutoScalingGroupNam $asgName).Instances
        if ($instances.Count -lt $config["min"]) {
            Write-Host $asgName": Waiting on servers"
            $asgsPending++
        }else {
            $instancesPending = 0
            $instancesReady = 0
            foreach($instance in $instances) {
              if ($instance.LifecycleState.Value -ne "InService") {
                $instancesPending++
              }
              else {
                $instancesReady++
              }
            }
            Write-Host $asgName "Instances Ready:" $instancesReady ", Instances Pending:" $instancesPending
            if ($instancesPending -gt 0) {
                $asgsPending++
            }
            else {
                $asgsCompleted++
            }
        }
    }

    Write-Host "Pending Groups:" $asgsPending", Completed Groups:" $asgsCompleted
    if ($asgsPending -eq 0) {
        break
    }

    $tries++
}

Write-Host "Done!"



