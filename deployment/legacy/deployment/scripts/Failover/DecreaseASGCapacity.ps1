Param(
    [string]$regionabbrev = "uw2",
    [string]$environment,
    [string]$fis,
    [int]$maxtries = 1000
)

$regionabbrev = $regionabbrev.ToLower()
$fis = $fis.ToLower()
$environment = $environment.ToLower()

Write-Host "Region abbrev    = $regionabbrev"
Write-Host "FIs              = $fis"
Write-Host "Environment      = $environment"
Write-Host "================================================================================"

function ScaleDown {
    param (
        [string]$asgName,
        [int]$min,
        [int]$max
        )

    Write-Host "Scaling down: $asgName to Min: $min, Max: $max"
    Update-ASAutoScalingGroup -AutoScalingGroupName $asgName -MinSize $min -MaxSize $max -DesiredCapacity $min
}

$allGroups = @()
foreach($fi in $fis.Split(',')) {
    $allGroups += "$regionabbrev-cpt-enc-$fi-$environment-logqserver-asg"
    $allGroups += "$regionabbrev-cpt-enc-$fi-$environment-app-asg"
    $allGroups += "$regionabbrev-cpt-enc-$fi-$environment-www-asg"
    $allGroups += "$regionabbrev-cpt-enc-$fi-$environment-svc-asg"
    $allGroups += "$regionabbrev-cpt-enc-$fi-$environment-winsvc-asg"
    $allGroups += "$regionabbrev-cpt-enc-$fi-$environment-taskmanweb-asg"
    $allGroups += "$regionabbrev-cpt-enc-$fi-$environment-taskmanapp-asg"
}

$allGroups += "$regionabbrev-cpt-enc-shrd-$environment-fax-asg"
$allGroups += "$regionabbrev-cpt-enc-shrd-$environment-proc-asg"

Write-Host "All Groups   =" ($allGroups -join ", ")
Write-Host "================================================================================"

foreach ($asgName in $allGroups) {
    ScaleDown $asgName -min 0 -max 0
}

$tries = 0
while ($tries -lt $maxTries) {
    Start-Sleep -Seconds 10
    Write-Host "================================================================================"

    # Check status of all groups
    $groupsPending = 0
    $groupsCompleted = 0
    foreach($asgName in $allGroups) {
        $instances = (Get-ASAutoScalingGroup $asgname).Instances
        if ($instances.Count -gt 0) {
            Write-Host $asgName "Instances Remaining:" $instances.Count
            $groupsPending++
        }
        else {
            Write-Host $asgName "Completed"
            $groupsCompleted++
        }
    }

    Write-Host "Pending Groups:" $groupsPending", Completed Groups:" $groupsCompleted
    if ($groupsPending -eq 0) {
        break
    }

    $tries++
}

Write-Host "Done!"