Param(
    [string]$env,
	[string]$fi,
	[string]$service
)

Write-Host "Completing Lifecycle Hook"

Set-Variable -name region -value (Invoke-RestMethod -Method Get -Uri http://169.254.169.254/latest/meta-data/placement/region)
$regionabbrev = ($region.split('-') | foreach-object { $_[0] }) -join ""

Set-Variable -name instanceId -value (Invoke-RestMethod -uri http://169.254.169.254/latest/meta-data/instance-id)

$name = "${regionabbrev}-cpt-enc-${fi}-${env}-${service}".ToLower()
$asgname = "${name}-asg"
$lhname = "${name}-lh"

Complete-ASLifecycleAction -AutoScalingGroupName $asgname -LifecycleHookName $lhname -InstanceId $instanceId -LifecycleActionResult CONTINUE
