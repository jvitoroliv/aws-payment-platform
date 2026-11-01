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

# Types
$type_live  = 1
$type_async = 2

# AWS EC2 Statuses and Lifecycle States we care about
$stopped_statuses = ("stopped","shutting-down","terminated")
$standby_state = "Standby"
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
$servicesList += @{ "Type" = $type_async; "Services" = $asyncservices }		# not doing anything with async

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
					$asgitem = @{ 
						"Name"                   = $asgname;
						"Type"                   = $type;
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


foreach ($asg in $ASGlist) {
	$asgname = $asg.Name
	
	$now = Get-Date
	$nowStr = Get-Date -Format "yyyy-MM-dd HH:mm:ss" $now

	$lhname = $asgname.Substring(0,$asgname.Length-3)+"lh"
	
	Write-Host "$nowStr Checking ASG $asgname"

	$warm = Get-ASWarmPool -AutoScalingGroupName $asgname
	if ($warm.Instances.Count -gt 0) {
		Write-Host "  Deleting WarmPool"
		Remove-ASWarmPool -AutoScalingGroupName $asgname -ForceDelete $true -Force
	}

	Write-Host "  Resuming all processes."
	Resume-ASProcess -AutoScalingGroupName $asgname -Force

	$asgInstances = (Get-ASAutoScalingGroup -AutoScalingGroupName $asgname).Instances
	foreach($instance in $asgInstances) {
		$instanceId = $instance.InstanceId
		$lcstate = $instance.LifecycleState.Value
		if ($lcstate -eq $pendingwait_state) {
			Write-Host "  Completing stalled instance"
			Complete-ASLifecycleAction -AutoScalingGroupName $asgname -LifecycleHookName $lhname -InstanceId $instanceId -LifecycleActionResult CONTINUE
		}
		
		if ($lcstate -eq $standby_state) {
			Write-Host "  Dismounting leftover standby instance"
			Dismount-ASInstance -InstanceId $instanceId -AutoScalingGroupName $asgname -ShouldDecrementDesiredCapacity $false
		}
	}
}

Start-Sleep 60 # pause to allow asgs to update


# terminate any EC2 not in ASG

$ec2s = Get-EC2Instance # get all EC2s

foreach ($asg in $ASGlist) {
	$asgname = $asg.Name
	$asgInstances = (Get-ASAutoScalingGroup -AutoScalingGroupName $asgname).Instances
	$asgInstanceIds = $asgInstances | Foreach-Object { $_.InstanceId }
		
	$instancename = $asgname.Substring(0,$asgname.Length-4) # e.g. eu1-cpt-enc-finserv-qa-app

	foreach($ec2 in $ec2s.Instances) {
		$ec2instanceId = $ec2.InstanceId
		$ec2name = ($ec2.Tags | Where { $_.Key -eq "Name" }).Value
		
		if ($ec2name -eq $instancename)	{ # ec2 is associated with this ASG
			if (-not $asgInstanceIds.Contains($ec2instanceId)) { # but isn't in the list of instances actually in the ASG
				if (-not $stopped_statuses.Contains($ec2.State.Name.Value)) { # not already dead or dying
					# hasta la vista, baby
					Write-Host "  Terminating orphaned EC2 $ec2instanceId"
					try {
						Remove-EC2Instance -InstanceId $ec2instanceId -Force
					}
					catch {
						Write-Warning "  Unable to terminate EC2 instance $ec2instanceId"
					}
				}
			}
		}
	}
}


