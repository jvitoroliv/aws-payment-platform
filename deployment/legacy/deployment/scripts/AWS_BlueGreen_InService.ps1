Param(
	[string]$region = "us-east-1",
	[string]$fis,				# e.g. "pnc", but for Finserv, we'll do "finserv,shrd", so the shared services (FaxDispo and Processor) get done, too
	[string]$environment,
	[string]$liveservices,		# e.g. "www,app,svc" or "www,app,svc,fax,proc", but also maybe "www:0,app:45,svc:45" adding the optional seconds delay for some services, to help with syncronization
	[string]$asyncservices,		# e.g. "winsvc,logqserver"
	[string]$deployinfobucketname,
	[string]$releaseid,
	[int]$maxtries = 1000
)

Import-Module AWSPowerShell

if ($region.Contains('-')) {
	$regionabbrev = ($region.Split('-') | ForEach-Object { $_[0] }) -join ""
}
else {
	$regionabbrev = $region  # abbrev sent in, so backward compatibility
}
$keyfi = $fis.Split(',') | Select-Object -First 1


# States
$state_delay        = 1
$state_ready        = 2

$state_live_allpendingwait = 14
$state_live_inservice      = 15
$state_live_standby        = 16

$state_async_starting = 22
$state_async_running  = 23

$state_done         = 99


# Types
$type_live  = 1
$type_async = 2


# AWS EC2 Statuses and Lifecycle States we care about
$stopped_statuses = ("stopped","shutting-down","terminated")
$inservice_state = "InService"
$standby_state = "Standby"
$warmedrunning_state = "Warmed:Running"
$pendingwait_state = "Pending:Wait"

$regionabbrev	= $regionabbrev.ToLower()
$fis			= $fis.ToLower()
$environment	= $environment.ToLower()
$liveservices 	= $liveservices.ToLower()
$asyncservices	= $asyncservices.ToLower()

Write-Host "Region abbrev    = $regionabbrev"
Write-Host "FIs              = $fis"
Write-Host "Environment      = $environment"
Write-Host "Live Services    = $liveservices"
Write-Host "Async Services   = $asyncservices"
Write-Host ""


$servicesList = @()
$servicesList += @{ "Type" = $type_live;  "Services" = $liveServices  }
$servicesList += @{ "Type" = $type_async; "Services" = $asyncservices }


# get ASGlist for S3
$filename = "DeployInfo_${keyfi}_${releaseid}.json"
$s3objects = Get-S3Object -BucketName "$deployinfobucketname" -Region "$region" | Where-Object { $_.Key -match "$filename" }
if (-not $s3objects) {
	Write-Error "ERROR: DeployInfo file $filename not found."
	exit 1
}

$key = ($s3objects | Select-Object -Last 1).Key
$workingdir = "${env:System_DefaultWorkingDirectory}"
$localfile = "${workingdir}\${filename}"
Write-Host "Loading ASGlist $filename"
Copy-S3Object -BucketName "$deployinfobucketname" -Region "$region" -Key "$key" -LocalFile "$localfile"

$ASGlist = Get-Content $localfile | ConvertFrom-Json


# gettin' loopy with it

$starttime = Get-Date
$tries = 0
while ($tries -lt $maxtries) {
	Start-Sleep -Seconds 5
	Write-Host "================================================================================"


	$alldone = $true
	foreach ($asg in $ASGlist) {
		$asgname = $asg.Name
		$now = Get-Date
		$nowStr = Get-Date -Format "yyyy-MM-dd HH:mm:ss" $now

		if ($asg.State -ne $state_done) {
			Write-Host "$nowStr Checking ASG $asgname"
		}

		switch ($asg.State) {
			$state_delay { # not used in this part, just jump ahead
				$alldone = $false
				$asg.State = $state_ready
			}

			$state_ready {
				$alldone = $false

				# figger if live or async, and move to proper first state
				switch ($asg.Type) {
					$type_live {
						$asg.State = $state_live_allpendingwait
					}
					$type_async {
						$asg.State = $state_async_starting
					}
					default {
						Write-Host "  Unknown ASG type $($asg.Type), dafuq?"
					}
				}
			}


			# Live Service states

			$state_live_allpendingwait {
				$alldone = $false

				Write-Host "  Completing LifecycleHook for all new instances"

				$instances = (Get-ASAutoScalingGroup $asgname).Instances
				$lhname = $asgname.Substring(0,$asgname.Length-3)+"lh"
				
				# complete each new instance
				foreach ($instance in $instances) {
					if ($instance.LifecycleState.Value -eq $pendingwait_state) {
						Complete-ASLifecycleAction -AutoScalingGroupName $asgname -LifecycleHookName $lhname -InstanceId $instance.InstanceId -LifecycleActionResult CONTINUE
					}
				}
				
				$asg.State = $state_live_inservice
			}

			$state_live_inservice {
				$alldone = $false

				# target is at least one new instance running (doesn't have to be all)

				$instances = (Get-ASAutoScalingGroup $asgname).Instances
				# looking for one new instance that is fully up and running, aka InService

				$go = $false
				$origInstanceIds = $asg.OriginalInstanceIds

				# no whammies, no whammies!
				foreach ($instance in $instances) {
					$instanceId = $instance.InstanceId
					if (-not $origInstanceIds.Contains($instanceId)) {
						$lcstate = $instance.LifecycleState.Value
						Write-Host "  instance $instanceId LifecycleState $lcstate"
					
						if ($lcstate -eq $inservice_state) {
							$go = $true
							Write-Host "  Found a new instance running!"
							break
						}
					}
				}

				if ($go) { # got at least one new instance up and running, so freeze the old ones
					Write-Host "  All new instances InService"
					
					Write-Host "  Putting original instances on Standby"
					$instances = (Get-ASAutoScalingGroup $asgname).Instances
					$origInstanceIds = $asg.OriginalInstanceIds
					foreach($instance in $instances) {
						$instanceId = $instance.InstanceId
						if ($origInstanceIds.Contains($instanceId)) { # only looking at original instances
							$lcstate = $instance.LifecycleState.Value
							if ($lcstate -eq $inservice_state) {
								Enter-ASStandby -InstanceId $instanceId -AutoScalingGroupName $asgname -ShouldDecrementDesiredCapacity $true
							}
							else {
								Write-Host "  Huh, weird, instance $instanceId is not InService (is $lcstate)"
							}
						}
					}
					$asg.State = $state_live_standby
				}
				else {
					Write-Host "  still watching"
				}
			}

			$state_live_standby {
				$alldone = $false

				# target is all old instances to LifecycleState of Standby
				
				$instances = (Get-ASAutoScalingGroup $asgname).Instances
				$origInstanceIds = $asg.OriginalInstanceIds

				$go = $true;
				foreach ($instance in $instances) {
					$instanceId = $instance.InstanceId
					if ($origInstanceIds.Contains($instanceId)) { # only looking at original instances
						$lcstate = $instance.LifecycleState.Value
						Write-Host "  instance $instanceId LifecycleState $lcstate"
					
						if ($lcstate -ne $standby_state) {
							$go = $false
						}
					}
				}
				
				if ($go) {
					Write-Host "  All original instances now on StandBy"
					
					Write-Host "  Restoring original ASG settings"
					$min = $asg.OriginalMinSize
					$max = $asg.OriginalMaxSize
					Update-ASAutoScalingGroup -AutoScalingGroupName $asgname -MinSize $min -MaxSize $max
					
					$asg.State = $state_done
				}
				else {
					Write-Host "  still watching"
				}
			}


			
			# Async Service states
			
			$state_async_starting { # scale back up
				$alldone = $false

				Write-Host "  Restoring Launching of new instances"
				Resume-ASProcess -AutoScalingGroupName $asgname -ScalingProcess Launch -Force

				$asg.State = $state_async_running
			}
			
			$state_async_running {
				$alldone = $false

				$instances = (Get-ASAutoScalingGroup $asgname).Instances

				$origInstanceIds = $asg.OriginalInstanceIds
				$desiredInstances = $origInstanceIds.Count

				$allrunning = $true
				$numinstances = 0
				
				foreach ($instance in $instances) {
					$instanceId = $instance.InstanceId
					if (-not $origInstanceIds.Contains($instanceId)) { # only looking at new instances
						$numinstances++
						
						$lcstate = $instance.LifecycleState.Value
						Write-Host "  instance $instanceId LifecycleState $lcstate"
					
						if ($lcstate -ne $inservice_state) {
							$allrunning = $false
						}
					}
				}

				if (($numInstances -eq $desiredInstances) -and $allrunning) {
					Write-Host "  All new instances now Running!"
					$asg.State = $state_done
				}
				else {
					Write-Host "  still watching"
				}
			}
			
			$state_done {
				# nothing left to do.
			}
			
			default {
				Write-Host "  Unknown ASG state $($asg.State), dafuq?"
			}
		}
	}
	
	if ($alldone) {
		Write-Host "All ASGs done."
		break;
	}
	
	$tries++
}

if (-not $alldone) { # timed out
	Write-Error "ASG InServicing unsuccessful"
}
