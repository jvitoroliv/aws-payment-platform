Param(
	[string]$region = "us-east-1",
	[string]$fis,				# e.g. "pnc", but for Finserv, we'll do "finserv,shrd", so the shared services (FaxDispo and Processor) get done, too
	[string]$environment,
	[string]$liveservices,		# e.g. "www,app,svc" or "www,app,svc,fax,proc", but also maybe "www:0,app:45,svc:45", but if so, we're ignoring the delay
	[string]$asyncservices,		# e.g. "winsvc,logqserver"	# doesn't matter, completed during first script run
	[string]$deployinfobucketname = "",
	[string]$releaseid = "",
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
$state_ready          = 1

$state_livedetach     = 11
$state_livemonitor    = 12
$state_liveterminate  = 13

$state_asyncdetach    = 21
$state_asyncmonitor   = 22
$state_asyncterminate = 23

$state_done           = 99


# Types
$type_live  = 1
$type_async = 2

# AWS EC2 Statuses and Lifecycle States we care about
$stopped_statuses = ("stopped","shutting-down","terminated")
$inservice_state = "InService"
$standby_state = "Standby"
$detaching_state = "Detaching"
$unhealthy_status = "Unhealthy"

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
						if ($instance.LifecycleState.Value -eq $standby_state) {
							$standybyInstanceIds += $Instance.InstanceId
						}
						else {
							$instanceIds += $Instance.InstanceId 
						}
					}
				
					$asgitem = @{ 
						"Name"                   = $asgname;
						"Type"                   = $type;
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
						$asg.State = $state_livedetach
						Write-Host "  ready to go, live"
					}
					$type_async {
						$asg.State = $state_asyncdetach
						Write-Host "  ready to go, async"
					}
					default {
						Write-Host "  Unknown ASG type $($asg.Type), dafuq?"
					}
				}
			}


			# Live Service states

			$state_livedetach { # Detach saucer section!
				$alldone = $false

				$standbyInstanceIds = $asg.StandbyInstanceIds
				
				if ($standbyInstanceIds.Count -gt 0) {
					Dismount-ASInstance -InstanceId $standbyInstanceIds -AutoScalingGroupName $asgname -ShouldDecrementDesiredCapacity $false
					$asg.State = $state_livemonitor
				}
				else {
					Write-Warning "No instances in StandBy"
					$asg.State = $state_done
				}
			}

			$state_livemonitor { # watching the StandBy go ByeBye
				$alldone = $false

				# target is all old instances are gone (no StandBy or Detaching)

				$instances = (Get-ASAutoScalingGroup $asgname).Instances

				$go = $true
				foreach ($instance in $instances) {
					$instanceId = $instance.InstanceId
					$lcstate = $instance.LifecycleState.Value
					Write-Host "  instance $instanceId LifecycleState $lcstate"

					if (($lcstate -eq $standby_state) -or ($lcstate -eq $detaching_state)) {
						$go = $false
					}
				}

				if ($go) { # all StandBy and Detaching instances are gone
					Write-Host "  Terminating old standby instances"
					
					$standbyInstanceIds = $asg.StandbyInstanceIds
                    if ($standbyInstanceIds.Count -gt 0) {
						foreach($instanceId in $standbyInstanceIds) {
							try {
								Write-Host "  Terminating instance $instanceId"
								Remove-EC2Instance -InstanceId $instanceId -Force
							}
							catch {
								Write-Warning "  Unable to terminate EC2 instance $instanceId"
							}
						}
                    }
                    else {
                        Write-Warning "No instances in StandBy"
                    }

					$asg.State = $state_done
				}
				else {
					Write-Host "  still watching"
				}
			}


			# Async Service states

			$state_asyncdetach { # Drop 'em like they're hot
				$alldone = $false

				$standbyInstanceIds = $asg.StandbyInstanceIds
				
				if ($standbyInstanceIds.Count -gt 0) {
					Dismount-ASInstance -InstanceId $standbyInstanceIds -AutoScalingGroupName $asgname -ShouldDecrementDesiredCapacity $false
					$asg.State = $state_asyncmonitor
				}
				else {
					Write-Warning "No instances in StandBy"
					$asg.State = $state_done
				}
			}

			$state_asyncmonitor { # watching the StandBy go ByeBye
				$alldone = $false

				# target is all old instances are gone (no StandBy or Detaching)

				$instances = (Get-ASAutoScalingGroup $asgname).Instances

				$go = $true
				foreach ($instance in $instances) {
					$instanceId = $instance.InstanceId
					$lcstate = $instance.LifecycleState.Value
					Write-Host "  instance $instanceId LifecycleState $lcstate"

					if (($lcstate -eq $standby_state) -or ($lcstate -eq $detaching_state)) {
						$go = $false
					}
				}

				if ($go) { # all StandBy and Detaching instances are gone
					Write-Host "  Terminating old standby instances"
					
					$standbyInstanceIds = $asg.StandbyInstanceIds
                    if ($standbyInstanceIds.Count -gt 0) {
						foreach($instanceId in $standbyInstanceIds) {
							try {
								Write-Host "  Terminating instance $instanceId"
								Remove-EC2Instance -InstanceId $instanceId -Force
							}
							catch {
								Write-Warning "  Unable to terminate EC2 instance $instanceId"
							}
						}
                    }
                    else {
                        Write-Warning "No instances in StandBy"
                    }

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
	
