Param(
	[Parameter(Mandatory=$true)]
	[string]$env = "UAT",	# UAT, PROD
    [Parameter(Mandatory=$true)]
    [string]$firstRestoreStep
)

. C:\CorePlatform\SharedFunctions.ps1
$restoring = $false
Set-Variable -name instance_id -value (Invoke-RestMethod -uri http://169.254.169.254/latest/meta-data/instance-id)
$instance = Get-EC2Instance -InstanceId $instance_id
foreach ($tag in $instance.instances[0].tags) {
    if ($tag.key -ceq "Restoring") {
        Write-Msg "Restoring Tag found: $($tag.Value)"
        $restoring = ([System.Convert]::ToBoolean($tag.Value))
    }
}

if ($restoring) {
    if (Test-Path C:\work\restore.txt) {
        $restoreStep = get-content c:\work\restore.txt -TotalCount 1
        if ($restoreStep) {
            # Some other stage of the process
            Write-Msg "Running $restoreStep"
            Powershell.exe -File $restoreStep $env
        }
    }
    else {
        # Step 1
        Write-Msg "Running $firstRestoreStep"
        Powershell.exe -File $firstRestoreStep $env
    }
}
else {
    Write-Msg "No restore process to run."
}