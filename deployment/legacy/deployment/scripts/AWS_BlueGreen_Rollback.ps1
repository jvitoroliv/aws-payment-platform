Param(
	[string]$regionabbrev = "ue1",
	[string]$fis,				# e.g. "pnc", but for Finserv, we'll do "finserv,shrd", so the shared services (FaxDispo and Processor) get done, too
	[string]$environment,
	[string]$liveservices,		# e.g. "www,app,svc" or "www,app,svc,fax,proc", but also maybe "www:0,app:45,svc:45", but if so, we're ignoring the delay
	[string]$asyncservices,		# e.g. "winsvc,logqserver"
	[int]$maxtries = 500
)

Import-Module AWSPowerShell

# States
$state_ready               = 1

$state_liveswapstandby     = 11
$state_livemonitor         = 12

$state_asyncstandby        = 21
$state_asyncstandbywait    = 22
$state_asyncstopped        = 23
$state_asyncinservice      = 24

$state_done                = 99


# Types
$type_live  = 1
$type_async = 2

# AWS EC2 Statuses and Lifecycle States we care about
$stopped_statuses = ("stopped","shutting-down","terminated")
$stopped_status = "stopped"
$running_status = "running"
$inservice_state = "InService"
$standby_state = "Standby"


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
			$service = $serviceitem.Split(':')[0]

			foreach ($fi in $fis.Split(',')) {
				$asgname = "{0}-cpt-enc-{1}-{2}-{3}-asg" -f $regionabbrev, $fi, $environment, $service
	
				$asg = Get-ASAutoScalingGroup $asgname # get ASG details, before any changes

				if ($asg) {
					# get InstanceId's
					$instanceIds = @()
					$standybyInstanceIds = @()
					foreach($instance in $asg.Instances) {
						$instanceStatus = Get-EC2InstanceStatus $instanceId -IncludeAllInstance $true
						$instanceState = $instanceStatus.InstanceState.Name.Value
						
						if ($instance.LifecycleState.Value -eq $inservice_state) {
							$instanceIds += $Instance.InstanceId 
						}
						if ($instance.LifecycleState.Value -eq $standby_state) {
							$standybyInstanceIds += $Instance.InstanceId
						}
						# in another state? ignore
					}
				
					$asgitem = @{ 
						"Name"                   = $asgname;
						"Type"                   = $type;
						"OriginalMinSize"        = $asg.MinSize; 
						"OriginalMaxSize"        = $asg.MaxSize;
						"NewInstanceIds"         = $instanceIds;
						"StandbyInstanceIds"     = $standybyInstanceIds;
						"State"                  = $state_ready;
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
	Write-Host "========================================"

	$alldone = $true
	foreach ($asg in $ASGlist) {
		$asgname = $asg.Name
		$now = Get-Date
		$nowStr = Get-Date -Format "yyyy-MM-dd HH:mm:ss" $now

		if ($asg.State -ne $state_done) {
			Write-Host "$nowStr Checking ASG $asgname"
		}

		switch ($asg.State) {
			$state_ready {
				$alldone = $false

				# figger if live or async, and move to proper first state
				switch ($asg.Type) {
					$type_live {
						$asg.State = $state_liveswapstandby
						Write-Host "  ready to go, sync"
					}
					$type_async {
						$asg.State = $state_asyncstandby
						Write-Host "  ready to go, async"
					}
					default {
						Write-Host "  Unknown ASG type $($asg.Type), dafuq?"
					}
				}
			}
			

			# Live Service states

			$state_liveswapstandby { # you put your left foot in, you take your left foot out...
				$alldone = $false

				$newInstanceIds = $asg.NewInstanceIds
				$standbyInstanceIds = $asg.standbyInstanceIds

				Write-Host "  Upping ASG MaxSize for elbow room"
				Update-ASAutoScalingGroup -AutoScalingGroupName $asgname -MaxSize 100
				
				Write-Host "  Move StandBy instances to InService"
				if ($standbyInstanceIds.Count -gt 0) {
					Exit-ASStandby -InstanceId $standbyInstanceIds -AutoScalingGroupName $asgname
				}
				else {
					Write-Warning "No instances in StandBy"
				}

				Write-Host "  Move InService instances StandBy"
				if ($newInstanceIds.Count -gt 0) {
					Enter-ASStandby -InstanceId $newInstanceIds -AutoScalingGroupName $asgname -ShouldDecrementDesiredCapacity $true
				}
				else {
					Write-Warning "No instances InService"
				}
				
				$asg.State = $state_livemonitor
			}

			$state_livemonitor { # watching the ASG.  
				$alldone = $false

				# target is all StandBy's are InService, and all InService as StandBy

				$instances = (Get-ASAutoScalingGroup $asgname).Instances
				# looking for one new instance that has "ok" status

				$go = $true
				$newInstanceIds = $asg.NewInstanceIds
				$standbyInstanceIds = $asg.StandbyInstanceIds

				# no whammies, no whammies!
				foreach ($instance in $instances) {
					$instanceId = $instance.InstanceId
					$lcstate = $instance.LifecycleState.Value
					Write-Host "  instance $instanceId LifecycleState $lcstate"
					
					if ($newInstanceIds.Contains($instanceId)) { # going to StandBy
						if ($lcstate -ne $standby_state) { $go = $false }
					}
					elseif ($standbyInstanceIds.Contains($instanceId)) { # going to InService
						if ($lcstate -ne $inservice_state) { $go = $false }
					}
				}

				if ($go) { # all flipped
					Write-Host "  All instances flipped"

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

			$state_asyncstandby {
				$alldone = $false

				Write-Host "  Lowering ASG MinSize because we'll be hitting zero"
				Update-ASAutoScalingGroup -AutoScalingGroupName $asgname -MinSize 0

				Write-Host "  Putting 'new' instances on Standby"

				$instances = (Get-ASAutoScalingGroup $asgname).Instances

				$newInstanceIds = $asg.NewInstanceIds
				$standbyInstanceIds = $asg.standbyInstanceIds

				foreach($instance in $instances) {
					$instanceId = $instance.InstanceId
					if ($newInstanceIds.Contains($instanceId)) { # only looking at 'new' instances
						$lcstate = $instance.LifecycleState.Value
						if ($lcstate -eq $inservice_state) {
							Enter-ASStandby -InstanceId $instanceId -AutoScalingGroupName $asgname -ShouldDecrementDesiredCapacity $true # we don't want replacements to start spinning up
						}
						else {
							Write-Host "  Huh, weird, instance $instanceId is not InService (is $lcstate)"
						}
					}
				}
				
				Write-Host "  Waiting for all 'new' instance to go to StandBy"
				$asg.State = $state_asyncstandbywait
			}
			
			$state_asyncstandbywait {
				$alldone = $false

				# target is all 'new' instances to LifecycleState of Standby
				
				$instances = (Get-ASAutoScalingGroup $asgname).Instances

				$newInstanceIds = $asg.NewInstanceIds
				$standbyInstanceIds = $asg.standbyInstanceIds

				$go = $true;
				foreach ($instance in $instances) {
					$instanceId = $instance.InstanceId
					if ($newInstanceIds.Contains($instanceId)) { # only looking at 'new' instances
						$lcstate = $instance.LifecycleState.Value
						Write-Host "  instance $instanceId LifecycleState $lcstate"
					
						if ($lcstate -ne $standby_state) {
							$go = $false
						}
					}
				}
				
				if ($go) {
					Write-Host "  All 'new' instances now on StandBy"
					
					Write-Host "  Stopping 'new' instances"
					foreach($instanceId in $newInstanceIds) {
						Stop-EC2Instance -InstanceId $instanceId
					}
					
					$asg.State = $state_asyncstopped
				}
				else {
					Write-Host "  still watching"
				}
			}
			
			$state_asyncstopped {
				$alldone = $false

				# target is all "new" instances have stopped

				$newInstanceIds = $asg.newInstanceIds
				$standbyInstanceIds = $asg.standbyInstanceIds

				$allstopped = $true
				foreach ($instanceId in $newInstanceIds) {
					$instanceStatus = Get-EC2InstanceStatus $instanceId -IncludeAllInstance $true
					$instanceState = $instanceStatus.InstanceState.Name.Value
					Write-Host "  instance $instanceId State $instanceState"
					
					if ($instanceState -ne $stopped_status) { # not stopped yet
						$allstopped = $false
					}
				}

				if ($allstopped) { # all stopped
					Write-Host "  All 'new' running instances now stopped"
					
					Write-Host "  Restarting 'old' instances"
					foreach($instanceId in $standbyInstanceIds) {
						Start-EC2Instance -InstanceId $instanceId
					}
					
					$asg.State = $state_asyncrunning
				}
				else {
					Write-Host "  still watching"
				}
			}
			
			$state_asyncrunning {
				$alldone = $false

				# target is all 'old' instances running (still on StandBy)

				$go = $true
				$any = $false

				$instances = (Get-ASAutoScalingGroup $asgname).Instances
				$newInstanceIds = $asg.newInstanceIds
				$standbyInstanceIds = $asg.standbyInstanceIds

				foreach ($instance in $instances) {
					$instanceId = $instance.InstanceId
					if ($standbyInstanceIds.Contains($instanceId)) { # only looking for 'old' instances
						$any = $true
						
						$instanceStatus = Get-EC2InstanceStatus $instanceId -IncludeAllInstance $true
						$instanceState = $instanceStatus.InstanceState.Name.Value
						Write-Host "  instance $instanceId State $instanceState"
					
						if ($instanceState -ne $running_status) {
							$go = $false
						}
					}
				}
				
				if ($any -and $go) { # all running
					Write-Host "  All 'old' servers running"
					
					Write-Host "  Move 'old' instances to InService"
					if ($standbyInstanceIds.Count -gt 0) {
						Exit-ASStandby -InstanceId $standbyInstanceIds -AutoScalingGroupName $asgname
					}
					
					$asg.State = $state_asyncinservice
				}
				else {
					Write-Host "  still watching"
				}
			}

			$state_asyncinservice {
				$alldone = $false

				# target is all 'old' instances are InService

				$instances = (Get-ASAutoScalingGroup $asgname).Instances

				$newInstanceIds = $asg.NewInstanceIds
				$standbyInstanceIds = $asg.StandbyInstanceIds

				# no whammies, no whammies!
				$go = $true
				foreach ($instance in $instances) {
					$instanceId = $instance.InstanceId
					if ($standbyInstanceIds.Contains($instanceId)) { # only checking 'old' instances
						$lcstate = $instance.LifecycleState.Value
						Write-Host "  instance $instanceId LifecycleState $lcstate"
					
						if ($lcstate -ne $inservice_state) { 
							$go = $false
						}
					}
				}

				if ($go) { # all 'old' are back InService
					Write-Host "  All instances flipped"

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
	
