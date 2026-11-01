Param(
	[string]$regionabbrev = "ue1",
	[string]$fis,				# e.g. "pnc", but for Finserv, we'll do "finserv,shrd", so the shared services (FaxDispo and Processor) get done, too
	[string]$environment,
	[string]$liveservices,		# e.g. "www,app,svc" or "www,app,svc,fax,proc", but also maybe "www:0,app:45,svc:45" adding the optional seconds delay for some services, to help with syncronization
	[string]$asyncservices,		# e.g. "winsvc,logqserver"
	[int]$maxtries = 1000
)

Import-Module AWSPowerShell

# States
$state_delay        = 1
$state_ready        = 2

$state_live_start          = 11
$state_live_warmedrunning  = 12
$state_live_pendingwait    = 13
$state_live_allpendingwait = 14
$state_live_inservice      = 15
$state_live_standby        = 16

$state_async_standby      = 21
$state_async_standbywait  = 22
$state_async_stopped      = 23
$state_async_running      = 24

$state_done         = 99


# Types
$type_live  = 1
$type_async = 2


# AWS EC2 Statuses and Lifecycle States we care about
$stopped_status = "stopped"
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

$ASGlist = @()

# validate services
foreach ($serviceList in $servicesList) {
	$services = $serviceList.Services
	$type = $serviceList.Type

	if ($services) {
		foreach ($serviceitem in $services.Split(',')) {
			$serviceparts = $serviceitem.Split(':')
			$service = $serviceparts[0]
			if ($serviceparts.Count -eq 2) {
				$delay = [int]$serviceparts[1]
			}
			else {
				$delay = 0
			}

			foreach ($fi in $fis.Split(',')) {
				$asgname = "{0}-cpt-enc-{1}-{2}-{3}-asg" -f $regionabbrev, $fi, $environment, $service
	
				$asg = Get-ASAutoScalingGroup $asgname # get ASG details, before any changes

				if ($asg) {
					# get InstanceId's
					$instanceIds = @()
					foreach($instance in $asg.Instances) {
						if ($instance.LifecycleState.Value -ne $standby_state) { # don't count instances on Standby
							$instanceIds += $instance.InstanceId 
						}
					}
				
					$asgitem = @{ 
						"Name"                   = $asgname;
						"Type"                   = $type;
						"OriginalMinSize"        = $asg.MinSize; 
						"OriginalMaxSize"        = $asg.MaxSize;
						"DesiredInstances"       = $instanceIds.Count * 2;
						"OriginalInstanceIds"    = $instanceIds;
						"Delay"                  = $delay;
					}
					if ($delay -gt 0) {
						$asgitem.State = $state_delay
					}
					else {
						$asgitem.State = $state_ready
					}
				
					$ASGlist += $asgitem
				}
				else {
					Write-Warning "ASG $asgname not found."
				}
			}
		}
	}
}

if ($ASGlist.count -eq 0) {
	Write-Error "ERROR: No ASGs matching parameters."
	exit 1
}



# gettin' loopy with it

$starttime = Get-Date
$tries = 0
while ($tries -lt $maxtries) {
	Start-Sleep -Seconds 5
	Write-Host "================================================================================"


	# are all live ASGs in pendingwait state?
	$allsyncpendingwait = $true
	foreach ($asg in $ASGlist) {
		if ($asg.Type -eq $type_live) {
			$allsyncpendingwait = $allsyncpendingwait -and ($asg.State -eq $state_live_allpendingwait)
		}
	}


	$alldone = $true
	foreach ($asg in $ASGlist) {
		$asgname = $asg.Name
		$now = Get-Date
		$nowStr = Get-Date -Format "yyyy-MM-dd HH:mm:ss" $now

		if ($asg.State -ne $state_done) {
			Write-Host "$nowStr Checking ASG $asgname"
		}

		switch ($asg.State) {
			$state_delay { # yawn, 10 more minutes...
				$alldone = $false

				$elapsed = [int]($now - $starttime).TotalSeconds
				if ($elapsed -lt $asg.Delay) { 
					# too soon, keep waiting
					Write-Host "  waiting ($elapsed of $($asg.Delay))"
				}
				else { # time to go!
					Write-Host "  time's up.  getting to work"
					$asg.State = $state_ready
				}
			}

			$state_ready {
				$alldone = $false

				# figger if live or async, and move to proper first state
				switch ($asg.Type) {
					$type_live {
						$asg.State = $state_live_start
						Write-Host "  ready to go, live"
					}
					$type_async {
						$asg.State = $state_async_standby
						Write-Host "  ready to go, async"
					}
					default {
						Write-Host "  Unknown ASG type $($asg.Type), dafuq?"
					}
				}
			}

			# Live Service states

			$state_live_start { # come on baby light my fire
				$alldone = $false

				Write-Host "  Creating WarmPool"

				$warmpoolSize = $asg.OriginalInstanceIds.Count
				Write-ASWarmPool -AutoScalingGroupName $asgname -MinSize $warmpoolSize -MaxGroupPreparedCapacity $warmpoolSize -PoolState "Running"
				
				$asg.State = $state_live_warmedrunning
			}
			
			$state_live_warmedrunning { # who turned the thermostat up?
				$alldone = $false

				# target is all warmpool instances are in state Warmed:Running
				
				$instances = (Get-ASWarmPool $asgname).Instances
				
				Write-Host "  Checking WarmPool"
				$go = $true
				$any = $false
				foreach ($instance in $instances) {
					$any = $true
					$instanceId = $instance.InstanceId
					$lcstate = $instance.LifecycleState.Value
					Write-Host "  instance $instanceId LifecycleState $lcstate"
						
					$go = $go -and ($instance.LifecycleState.Value -eq $warmedrunning_state)
				}
				
				if ($any -and $go) { # Scale me up, before you go-go 
					Write-Host "  All warmed-up"

					$newinstances = $asg.DesiredInstances
					Write-Host "  Scaling out to $newinstances instances"
					Update-ASAutoScalingGroup -AutoScalingGroupName $asgname -DesiredCapacity $newinstances -MaxSize 100
					
					$asg.State = $state_live_pendingwait
				}
				else {
					Write-Host "  still watching"
				}
			}

			$state_live_pendingwait { # watching the ASG for new instances in waiting state  
				$alldone = $false

				# target is all new instances in state Pending:Wait

				$instances = (Get-ASAutoScalingGroup $asgname).Instances

				$go = $true
				$any = $false
				$origInstanceIds = $asg.OriginalInstanceIds
				foreach ($instance in $instances) {
					$instanceId = $instance.InstanceId
					$lcstate = $instance.LifecycleState.Value
					if (-not $origInstanceIds.Contains($instanceId)) {
						# ignore inservice and standby
						if (($lcstate -eq $inservice_state) -or ($lcstate -eq $standby_state)) {
							Write-Host "  instance $instanceId LifecycleState $lcstate -- ignoring"
						}
						else {
							$any = $true
							Write-Host "  instance $instanceId LifecycleState $lcstate"

							$go = $go -and ($instance.LifecycleState.Value -eq $pendingwait_state)
						}
					}
				}

				if ($any -and $go) {
					Write-Host "  Deleting WarmPool"

					# delete the warmpool
					Remove-ASWarmPool -AutoScalingGroupName $asgname -ForceDelete $true -Force
					
					$asg.State = $state_live_allpendingwait
				}
				else {
					Write-Host "  still watching"
				}
			}

			$state_live_allpendingwait {
				$alldone = $false

				# target is ALL live ASGs to be in the allpendingwait state 

				# check happened before the asg loop, so none can sneak ahead and break the sync
				if ($allsyncpendingwait) { 
					Write-Host "  All ASGs synced up"

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
				else {
					Write-Host "  still waiting for all ASG to sync-up"
				}
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

			$state_async_standby {
				$alldone = $false

				Write-Host "  Putting original instances on Standby"

				$instances = (Get-ASAutoScalingGroup $asgname).Instances
				$origInstanceIds = $asg.OriginalInstanceIds
				foreach($instance in $instances) {
					$instanceId = $instance.InstanceId
					if ($origInstanceIds.Contains($instanceId)) { # only looking at original instances
						$lcstate = $instance.LifecycleState.Value
						if ($lcstate -eq $inservice_state) {
							Enter-ASStandby -InstanceId $instanceId -AutoScalingGroupName $asgname -ShouldDecrementDesiredCapacity $false # we want the replacements to start spinning up
						}
						else {
							Write-Host "  Huh, weird, instance $instanceId is not InService (is $lcstate)"
						}
					}
				}
							
				$asg.State = $state_async_standbywait
			}
			
			$state_async_standbywait {
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
					
					Write-Host "  Stopping original instances"
					$instances = (Get-ASAutoScalingGroup $asgname).Instances
					$origInstanceIds = $asg.OriginalInstanceIds
					foreach($instance in $instances) {
						$instanceId = $instance.InstanceId
						if ($origInstanceIds.Contains($instanceId)) { # only looking at original instances
							$lcstate = $instance.LifecycleState.Value
							if ($lcstate -eq $standby_state) {
								Stop-EC2Instance -InstanceId $instanceId
							}
							else {
								Write-Host "  Huh, weird, instance $instanceId is not on StandBy (is $lcstate)"
							}
						}
					}
					
					$asg.State = $state_async_stopped
				}
				else {
					Write-Host "  still watching"
				}
			}
			
			$state_async_stopped {
				$alldone = $false

				# target is all instances have stopped

				$origInstanceIds = $asg.OriginalInstanceIds

				$allstopped = $true
				foreach ($instanceId in $origInstanceIds) {
					$instanceStatus = Get-EC2InstanceStatus $instanceId -IncludeAllInstance $true
					$instanceState = $instanceStatus.InstanceState.Name.Value
					Write-Host "  instance $instanceId State $instanceState"
					
					if ($instanceState -ne $stopped_status) { # not stopped yet
						$allstopped = $false
					}
				}

				if ($allstopped) { # all stopped
					Write-Host "  All original instances now stopped"
					
					Write-Host "  Waiting for new instances to be ready"
					$asg.State = $state_async_running
				}
				else {
					Write-Host "  still watching"
				}
			}
			
			$state_async_running {
				$alldone = $false

				# target is at least one InService

				$instances = (Get-ASAutoScalingGroup $asgname).Instances
				$origInstanceIds = $asg.OriginalInstanceIds

				$go = $false
				foreach ($instance in $instances) {
					$instanceId = $instance.InstanceId
					if (-not $origInstanceIds.Contains($instanceId)) { # only looking for new instances
						$lcstate = $instance.LifecycleState.Value
						Write-Host "  instance $instanceId LifecycleState $lcstate"
					
						if ($lcstate -eq $inservice_state) {
							$go = $true
							Write-Host "  Found a new instance running!"
							break
						}
					}
				}
				
				if ($go) { # at least one inservice
					Write-Host "  New server InService"
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
	Write-Error "ASG scaling unsuccessful"
}
