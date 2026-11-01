Param(
	[string]$regionabbrev = "ue1",
	[string]$fis,			# e.g. "pnc", but for Finserv, we'll do "finserv,shrd", so the shared services (FaxDispo and Processor) get done, too
	[string]$environment,
	[string]$services   	# e.g. "www,app,svc"
)

Import-Module AWSPowerShell

$regionabbrev = $regionabbrev.ToLower()
$fis          = $fis.ToLower()
$environment  = $environment.ToLower()
$services     = $services.ToLower()

$services.Split(',') | Foreach-Object {
	$service = $_
	
	$fis.Split(',') | Foreach-Object {
		$fi = $_
	
		$tgname = ("{0}-cpt-enc-{1}-{2}-{3}-tg" -f $regionabbrev, $fi, $environment, $service).ToLower()
		Write-Host "TG $tgname"
		try {
			$tg = Get-ELB2TargetGroup -Name $tgname
		}
		catch {
			$tg = ""
		}
	
		if (-not $tg) {
			Write-Warning "$tgname not found"
		}
		else {
			$tgarn = $tg.TargetGroupArn
	
			#$tga = Get-ELB2TargetGroupAttribute -TargetGroupArn "$tgarn"
			#$lba = $tga | Where { $_.Key -eq "load_balancing.algorithm.type" }
			#$lbat = $lba.Value
			#Write-Host "  currently $lbat"
			
			Edit-ELB2TargetGroupAttribute -TargetGroupArn "$tgarn" -Attribute @{Key = 'load_balancing.algorithm.type'; Value = 'least_outstanding_requests'}
		}
	}
}
