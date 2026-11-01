Param(
    [Parameter(Mandatory=$true)]
    [String] $describeInstancesFilterValue,
    [Parameter(Mandatory=$true)]
    [String] $commandId,
    [Parameter(Mandatory=$true)]
    [ValidateRange(0, 100000)]
    [int] $timeout,
    [bool] $runningServersOnly = $false
)

[System.Collections.ArrayList]$groupedInstanceIds
if ($runningServersOnly) 
{
    $groupedInstanceIds = aws ec2 describe-instances --filters $describeInstancesFilterValue  Name=instance-state-name,Values=running `
        --output text --query "Reservations[*].Instances[*].InstanceId"
}
else 
{
    $groupedInstanceIds = aws ec2 describe-instances --filters $describeInstancesFilterValue `
    --output text --query "Reservations[*].Instances[*].InstanceId"
}

[System.Collections.ArrayList]$instanceIds = @()
#this is for when EC2s are launched as part of the same launch command; they will be grouped together
foreach ($instanceId in $groupedInstanceIds)
{
    $splitInstanceIds = $instanceId -split "\t"
    foreach ($splitInstanceId in $splitInstanceIds)
    {
        $instanceIds.Add($splitInstanceId)
    }
}

Write-Host "instance ids to check:"
Write-Host $instanceIds

$instancesToCheck = $instanceIds.Count
[System.Collections.ArrayList]$successes = @()
[System.Collections.ArrayList]$failures = @()

$timeoutElapsed = $false
$timer = [Diagnostics.Stopwatch]::StartNew()
while ($instancesToCheck -gt 0 -and $timer.Elapsed.TotalSeconds -lt $timeout)
{
    [System.Collections.ArrayList]$instancesToRemove = @()
    foreach ($instanceId in $instanceIds)
    {
        Write-Host "Checking on instance id: $instanceId command id: $commandId"
        $invocation = aws ssm get-command-invocation --command-id "$commandId" --instance-id "$instanceId"  | ConvertFrom-Json
        if ($invocation.StatusDetails -eq "Success")
        {
            [void]$instancesToRemove.Add($instanceId)
            [void]$successes.Add("$($invocation.InstanceId) StatusDetails: $($invocation.StatusDetails), StandardOutputContent: $($invocation.StandardOutputContent), StandardErrorContent: $($invocation.StandardErrorContent)")
            $instancesToCheck -= 1
        }
        elseif ($invocation.StatusDetails -eq "Failed")
        {
            [void]$instancesToRemove.Add($instanceId)
            [void]$failures.Add("$($invocation.InstanceId) StatusDetails: $($invocation.StatusDetails), StandardOutputContent: $($invocation.StandardOutputContent), StandardErrorContent: $($invocation.StandardErrorContent)")
            $instancesToCheck -= 1
        }
    }
    
    foreach ($instance in $instancesToRemove)
    {
        $instanceIds.Remove($instance)
    }
}
$timer.Stop()
if ($timer.Elapsed.TotalSeconds -gt $timeout)
{
    $timeoutElapsed = $true
    Write-Host "The following instances did not complete within the $($timeout) second timeout:"
    foreach ($instanceId in $instanceIds)
    {
        $invocation = aws ssm get-command-invocation --command-id "$commandId" --instance-id "$instanceId"  | ConvertFrom-Json
        Write-Host "$instanceId StatusDetails: $($invocation.StatusDetails), StandardOutputContent: $($invocation.StandardOutputContent), StandardErrorContent: $($invocation.StandardErrorContent)"
    }
}
Write-Host "Succeeded:"
foreach ($success in $successes)
{
    Write-Host $success
}
Write-Host "Failed:"
foreach ($failure in $failures)
{
    Write-Host $failure
}
if ($failures.Count -gt 0)
{
    Write-Host "Failures were found, exiting with error status."
    exit 1
}
if ($timeoutElapsed)
{
    Write-Host "Timeout elapsed, exiting with error status."
    exit 1
}
