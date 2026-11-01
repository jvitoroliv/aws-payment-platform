Param(
	[string]$regionabbrev = "ue1",
	[string]$fi,
	[string]$environment,
	[string]$services,   # e.g. "www,app,svc,winsvc,jobsvr"
	[int]$maxtries = 30
)

Import-Module AWSPowerShell

$regionabbrev = $regionabbrev.ToLower()
$fi           = $fi.ToLower()
$environment  = $environment.ToLower()
$services     = $services.ToLower()

Write-Host "Region abbrev = $regionabbrev"
Write-Host "FI            = $fi"
Write-Host "Environment   = $environment"
Write-Host "Services      = $services"
Write-Host ""

# I've come here to chew bubblegum and verify ASGs, and I'm all out of bubblegum
$ASGlist = @()
$services.Split(',') | Foreach-Object {
	$service = $_
	$asgname = "{0}-cpt-enc-{1}-{2}-{3}-asg" -f $regionabbrev, $fi, $environment, $service
	
	$asg = Get-ASAutoScalingGroup $asgname

	if ($asg) {
		$ASGlist += $asgname
	}
	else {
		Write-Warning "ASG $asgname not found."
	}
}

if ($ASGlist.count -eq 0) {
	Write-Error "ERROR: No ASGs matching parameters."
}

$ASGlist | Foreach-Object {
	$asgname = $_
	Write-Host "Shutting down ASG $asgname"
	Update-ASAutoScalingGroup -AutoScalingGroupName $asgname -MinSize 0 -MaxSize 0
}

Write-Host ""
Write-Host ""
Write-Host "Polling for shutdown completion..."
Write-Host ""


$tries = 0
while ($tries -lt $maxtries) {
	Start-Sleep 60

	$totalinstances = 0;
	$ASGlist | Foreach-Object {
		$asgname = $_
		$instances = (Get-ASAutoScalingGroup $asgname).Instances.Count
		Write-Host "$asgname instances $instances"
		$totalinstances += $instances
	}
	
	if ($totalinstances -eq 0) {
		break;
	}

	Write-Host ""
	$tries++
}

Write-Host ""
if ($tries -lt $maxtries) {
	Write-Host ""
	Write-Host "All ASGs shutdown."
	Write-Host ""
}
else {
	Write-Error "ASGs have not shutdown within time limits."
}

