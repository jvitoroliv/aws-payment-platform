Param(
    [string]$regionabbrev = "uw2",
    [string]$environment,
    [string]$region = "us-west-2",
    [string]$hostedZoneName,
    [string]$fiLoadBalancerList,
    [string]$shrdLoadBalancerList,
    [string]$fis
)

$environment = $environment.ToLower()
$fis = $fis.ToLower()

$fiLoadBalancers = $fiLoadBalancerList.Split(',') | sort # will ensure order of batch servers in the param
$shrdLoadBalancers = $shrdLoadBalancerList.Split(',') | sort # will ensure order of batch servers in the param

# Get the hostedZoneId
$hostedZoneId = (Get-R53HostedZonesByName | Where-Object {($_.Name -eq ($hostedZoneName + '.')) -and ($_.Config.PrivateZone -eq $false)}).Id

Write-Host "HostedZoneId:" $hostedZoneId

foreach($fi in $fis.Split(',')) {
    foreach($fiLoadBalancer in $fiLoadBalancers) {
        Write-Host "Changing $fi load balancer $fiLoadBalancer"

        $loadBalancer = Get-ELB2LoadBalancer -Name "$regionabbrev-cpt-enc-$fi-$environment-$fiLoadBalancer-lb"

        $change1 = New-Object Amazon.Route53.Model.Change
        $change1.Action = "UPSERT"
        $change1.ResourceRecordSet = New-Object Amazon.Route53.Model.ResourceRecordSet
        $change1.ResourceRecordSet.Name = "$fi-$fiLoadBalancer-public.$hostedZoneName."
        $change1.ResourceRecordSet.Type = "A"
		
		$change1.ResourceRecordSet.AliasTarget = New-Object Amazon.Route53.Model.AliasTarget
		$change1.ResourceRecordSet.AliasTarget.HostedZoneId = $loadBalancer.CanonicalHostedZoneId
		$change1.ResourceRecordSet.AliasTarget.DNSName = $loadBalancer.DNSName
		$change1.ResourceRecordSet.AliasTarget.EvaluateTargetHealth = $true
		
        Write-Host $loadBalancer.DNSName $loadBalancer.CanonicalHostedZoneId
        Edit-R53ResourceRecordSet -HostedZoneId $hostedZoneId -ChangeBatch_Change $change1
    }
}

foreach($shrdLoadBalancer in $shrdLoadBalancers) {
    Write-Host "Changing shrd load balancer $fiLoadBalancer"

    $lbName = if ($shrdLoadBalancer -eq "ftp") { "cerbrus" } else { $shrdLoadBalancer }

    # Special case for FTP LB since it has another name
    $loadBalancer = Get-ELB2LoadBalancer -Name "$regionabbrev-cpt-enc-shrd-$environment-$lbName-lb"

    $change1 = New-Object Amazon.Route53.Model.Change
    $change1.Action = "UPSERT"
    $change1.ResourceRecordSet = New-Object Amazon.Route53.Model.ResourceRecordSet
    $change1.ResourceRecordSet.Name = "shrd-$shrdLoadBalancer-public.$hostedZoneName."
    $change1.ResourceRecordSet.Type = "A"
    
	$change1.ResourceRecordSet.AliasTarget = New-Object Amazon.Route53.Model.AliasTarget
	$change1.ResourceRecordSet.AliasTarget.HostedZoneId = $loadBalancer.CanonicalHostedZoneId
	$change1.ResourceRecordSet.AliasTarget.DNSName = $loadBalancer.DNSName
	$change1.ResourceRecordSet.AliasTarget.EvaluateTargetHealth = $true

    Write-Host $loadBalancer.DNSName $loadBalancer.CanonicalHostedZoneId
    Edit-R53ResourceRecordSet -HostedZoneId $hostedZoneId -ChangeBatch_Change $change1
}

Write-Host "Done!"