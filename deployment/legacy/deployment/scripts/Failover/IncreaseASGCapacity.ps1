Param(
    [string]$regionabbrev = "uw2",
    [string]$environment,
    [string]$fis,
    [int]$maxtries = 1000
)

<#
Example for UAT:
Desired min-max
uw2-cpt-enc-finserv-uat-logqserver-asg (5/7)
uw2-cpt-enc-finserv-uat-app-asg (5/7)
uw2-cpt-enc-finserv-uat-www-asg (5/7)
uw2-cpt-enc-finserv-uat-svc-asg (5/7)
uw2-cpt-enc-shrd-uat-fax-asg (2/4)
uw2-cpt-enc-shrd-uat-proc-asg (2/4)
uw2-cpt-enc-finserv-uat-winsvc-asg (1/1)
#>

$regionabbrev = $regionabbrev.ToLower()
$fis = $fis.ToLower()
$environment = $environment.ToLower()

Write-Host "Region abbrev    = $regionabbrev"
Write-Host "FIs              = $fis"
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

$fiveSevenGroups = @()
$oneOneGroups = @()
foreach($fi in $fis.Split(',')) {
    $fiveSevenGroups += "$regionabbrev-cpt-enc-$fi-$environment-logqserver-asg"
    $fiveSevenGroups += "$regionabbrev-cpt-enc-$fi-$environment-app-asg"
    $fiveSevenGroups += "$regionabbrev-cpt-enc-$fi-$environment-www-asg"
    $fiveSevenGroups += "$regionabbrev-cpt-enc-$fi-$environment-svc-asg"
    $oneOneGroups    += "$regionabbrev-cpt-enc-$fi-$environment-winsvc-asg"
    $oneOneGroups    += "$regionabbrev-cpt-enc-$fi-$environment-taskmanweb-asg"
    $oneOneGroups    += "$regionabbrev-cpt-enc-$fi-$environment-taskmanapp-asg"
}

$twoFourGroups = @("$regionabbrev-cpt-enc-shrd-$environment-fax-asg","$regionabbrev-cpt-enc-shrd-$environment-proc-asg")
$allGroups = $fiveSevenGroups + $twoFourGroups + $oneOneGroups

Write-Host "5/7 Groups   =" ($fiveSevenGroups -join ", ")
Write-Host "2/4 Groups   =" ($twoFourGroups -join ", ")
Write-Host "1/1 Groups   =" ($oneOneGroups -join ", ")
Write-Host "================================================================================"

foreach ($asgName in $fiveSevenGroups) {
    ScaleUp $asgName -min 5 -max 7
}

foreach ($asgName in $twoFourGroups) {
    ScaleUp $asgName -min 2 -max 4
}

foreach ($asgName in $oneOneGroups) {
    ScaleUp $asgName -min 1 -max 1
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
        if ($fiveSevenGroups.Contains($asgName) -AND $instances.Count -lt 5) {
            Write-Host $asgName": Waiting on servers"
            $groupsPending++
        }
        elseif ($twoFourGroups.Contains($asgName) -AND $instances.Count -lt 2) {
            Write-Host $asgName": Waiting on servers"
            $groupsPending++
        }
        elseif ($oneOneGroups.Contains($asgName) -AND $instances.Count -lt 1) {
            Write-Host $asgName": Waiting on servers"
            $groupsPending++
        }
        else {
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
                $groupsPending++
            }
            else {
                $groupsCompleted++
            }
        }
    }

    Write-Host "Pending Groups:" $groupsPending", Completed Groups:" $groupsCompleted
    if ($groupsPending -eq 0) {
        break
    }

    $tries++
}

Write-Host "Done!"