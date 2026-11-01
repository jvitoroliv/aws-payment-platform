<powershell>

function Write-Log
{
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory=$true)]
        [string] $LogGroupName,
        [Parameter(Mandatory=$true)]
        [string] $LogStreamName,
        [Parameter(Mandatory=$true)]
        [string] $LogString
    )

    If (-Not (Get-CWLLogGroup -LogGroupNamePrefix $LogGroupName)) {
        New-CWLLogGroup -LogGroupName $logGroupName
        #Since the loggroup does not exist, we know the logstream does not exist either
        $CWLSParam = @{
            LogGroupName = $logGroupName
            LogStreamName = $logStreamName
        }
        New-CWLLogStream @CWLSParam
    }

    # determine if the LogStream Exists
    If (-Not (Get-CWLLogStream -LogGroupName $logGroupName -LogStreamName $LogStreamName)) {
        $CWLSParam = @{
            LogGroupName = $logGroupName
            LogStreamName = $logStreamName
        }
        New-CWLLogStream @CWLSParam 
    }
            
    $logEntry = New-Object -TypeName 'Amazon.CloudWatchLogs.Model.InputLogEvent'
    $logEntry.Message = $LogString
    $logEntry.Timestamp = (Get-Date).ToUniversalTime()

    # get the next sequence token
    $SequenceToken = (Get-CWLLogStream -LogGroupName $LogGroupName -LogStreamNamePrefix $logStreamName).UploadSequenceToken

    # there will be no $SequenceToken when a new Stream is created to we adjust the parameters for this          
    if ($SequenceToken) {
        $CWLEParam = @{
            LogEvent      = $logEntry
            LogGroupName  = $logGroupName
            LogStreamName = $logStreamName
            SequenceToken = $SequenceToken
        }
        Write-CWLLogEvent @CWLEParam 
    } else {
        $CWLEParam = @{
            LogEvent      = $logEntry
            LogGroupName  = $logGroupName
            LogStreamName = $logStreamName
        }
        Write-CWLLogEvent @CWLEParam 
    }
}

function Write-Msg
{
    [CmdletBinding()]
    Param
    (
        [Parameter(Mandatory=$true, Position=0)]
        [string]$LogMessage
    )

    Write-Output ("{0} - {1}" -f (Get-Date), $LogMessage)
    Write-Log -LogGroupName "UserData" -LogStreamName $env:computername -LogString $LogMessage
}

function Get-EncArtifacts
{
    [CmdletBinding()]
    Param
    (
        [Parameter(Mandatory=$true, Position=0)]
        [string]$Env,
        [Parameter(Mandatory=$true, Position=1)]
        [string]$Params
    )

    Write-Msg "Enter Get-EncArtifacts"

    Push-Location C:\Temp

	$script_params_hash = @{}
	foreach ($pair in $Params -split ";")
	{
		$splits = $pair.Split(",")
		$key = $splits[0]
		$value = $splits[1]
		$script_params_hash.add($key,$value)
	}
	
	$branch = $script_params_hash["branch"]
    Write-Msg "Branch: $branch"

	try {
		$files = Get-S3Object -BucketName "coreplatform-artifacts-$Env".ToLower() -KeyPrefix "EC2Launch/" | Sort-Object -Property Key
		
		foreach ($file in $files) {
            $fileKey = $file.Key

			# include branch here, read from startup_script_params, e.g., branch=MS-48965
			if ($fileKey -like "EC2Launch/CorePlatform.*$branch*.zip" -or $fileKey -like "EC2Launch/JobManagement.*$branch*.zip") {
                Write-Msg "Found file: $fileKey"

				# remove prefix from object name
				$localFileName = Split-Path $fileKey -Leaf
                Write-Msg "localFileName: $localFileName"

				if (-not(Test-Path -Path $localFileName -PathType Leaf)) {
                    Write-Msg "File does not exist locally, read from S3"
					Read-S3Object -BucketName "coreplatform-artifacts-$Env".ToLower() -Key "$fileKey" -File "$localFileName"
				
					# find position of 2nd period in object name, e.g., CoreService.WWW. to create zip folder C:\CoreService\WWW
					$pos = $localFileName.IndexOf(".", $localFileName.IndexOf(".") + 1)
					$zipFolder = "C:\" + $localFileName.SubString(0, $pos).Replace(".", "\")
                    Write-Msg "zipFolder: $zipFolder"

                    Write-Msg "Unzipping artifact"
					7z x ".\$localFileName" -o"$zipFolder" -y
                    Write-Msg "Artifact done"
				} else {
					Write-Msg "File already exists, do not download"
				}
			}
		}
	}
	catch {
		Write-Msg "Exception: $_"
	}

    Pop-Location

    Write-Msg "Exit Get-EncArtifacts"
}

Set-ExecutionPolicy unrestricted -Scope CurrentUser -Force
Set-TimeZone "Eastern Standard Time"
New-Item -ItemType directory -Path C:\work -Force
Start-Transcript -Path C:\work\userdata.log -Append
Import-Module AWSPowerShell

Write-Msg "Starting"

# Metadata
Set-Variable -name az -value (Invoke-RestMethod -Method Get -Uri http://169.254.169.254/latest/meta-data/placement/availability-zone)
Set-Variable -name instance_id -value (Invoke-RestMethod -uri http://169.254.169.254/latest/meta-data/instance-id)
$region = $az.Substring(0, $az.length - 1)

# Env specific values  
$hostname               = "${hostname}"
$dnsDomain              = "${dns_domain}"
$adUser                 = "${coreplatform_env}/ad_service_account"
$adPassKey              = "${coreplatform_env}/ad_service_password"
$oupath                 = "${oupath}"
$dnsServerAddresses     = "${dnsServerAddresses}"
$env:GPO_PARAMS         = "${gpo_params}"
$env:TRANSFORM_FLAGS    = "${transform_flags}"
$env:COREPLATFORM_ENV      = "${coreplatform_env}"
$datadog_enable         = "${datadog_enable}"

Write-Msg "dd_on: $datadog_enable"

if ((Get-WmiObject win32_computersystem).partofdomain) {

    Write-Msg "Computer joined in AD"
    
    $env:COREPLATFORM_FI = "${coreplatform_fi}"
    $env:COREPLATFORM_FILIST = "${coreplatform_filist}"
    $env:COREPLATFORM_REGION = $region
    $env:COREPLATFORM_HOSTNAME = $env:computername
    $env:COREPLATFORM_SITEID = "${coreplatform_siteid}"
    $env:COREPLATFORM_SCRIPT_PARAMS = "${startup_script_params}"
    
    Write-Msg "Hostname is $env:COREPLATFORM_HOSTNAME"

    # Refresh artifacts in dev env. Check RefreshingArtifactsInDevEnv.md in this folder for more info how to use this.
    if ($env:COREPLATFORM_ENV.ToLower() -eq "dev" -and -not ([string]::IsNullOrWhiteSpace("$env:COREPLATFORM_SCRIPT_PARAMS"))) {
        Write-Msg "Refreshing artifacts"
        Get-EncArtifacts $env:COREPLATFORM_ENV $env:COREPLATFORM_SCRIPT_PARAMS
        Write-Msg "Done refreshing artifacts"
    }

    #sync time with DC
    Write-Msg "Sync the clock to domain controller"
    w32tm /config /syncfromflags:domhier
    net stop w32time
    net start w32time
    w32tm /resync

    # Re-register splunk so it picks up the new hostname.
    if (Test-Path "c:\program files\splunkuniversalforwarder\bin\splunk.exe") {
        Write-Msg "Re-registering Splunk"
        try
        {
            choco install splunk-universalforwarder --params="'/Register:true'" -y --force
            Write-Msg "Splunk registration complete"
        }
        catch
        {
            Write-Msg "Splunk registration failed: $_"
        }
    }

    Write-Msg "gpupdate"
    gpupdate /force

    if ($datadog_enable.ToLower() -eq "true") {
        # proceed
        Write-Msg "DataDog: inst"
        cinst datadog-agent --params="'/Apikey:${DD_API_KEY}'" -y  --version=7.53 --pre

        Write-Msg "DataDog: set hostname"
        $dd_fldr = "C:\ProgramData\Datadog"
        $dd_cfg= "$dd_fldr\datadog.yaml"

        Write-Msg "dd.yaml: $dd_cfg"

        Set-Location $dd_fldr

        $hn = $env:computername
        (Get-Content -path $dd_cfg -Raw).Replace('# hostname: <HOSTNAME_NAME>',"hostname: ""$hn""").Replace('# use_dogstatsd', 'use_dogstatsd').Replace('# dogstatsd_port', 'dogstatsd_port') | Set-Content -Path $dd_cfg

        Write-Msg "DataDog: restart. Sleeping for 30."
        Start-Sleep -Seconds 30
        Restart-Service -Name datadogagent -Force

        Write-Msg "DataDog: inst .net tracer"
        cinst datadog-dotnet-apm -y --version=2.50.0 --pre
    } else {
        Write-Msg "Skipping datadog for this environment"
    }

    Write-Msg "iisreset"
    if ((Get-WindowsFeature Web-Server).Installed) 
    {
        Start-Process "iisreset.exe" -NoNewWindow -Wait
    }

    Write-Msg "CrowdStrike: inst"
    cinst crowdstrike-falcon-sensor -y -s artifactory

    # Run startup script on server
    if (-not ([string]::IsNullOrWhiteSpace("${startup_script}"))) {
        Write-Msg "Running startup script"
        Set-Location ${startup_path}
        .\${startup_script}
        Write-Msg "Startup script complete"
    } else {
        Write-Msg "No startup script specified"
    }

    Write-Msg "Done"
    Stop-Transcript

} else {

    Write-Msg "Computer NOT joined in AD"

    # check if restart has already occurred, if so then stop and write out an error for some alarm to find
    if (Test-Path C:\work\restart.txt) {
        Write-Msg "Error: restart has already occurred and computer has not joined AD, stopping script"
        exit 
    }

    Write-Msg "Install RSAT-AD-PowerShell"
    Install-WindowsFeature -Name RSAT-AD-PowerShell

    # set up the FI eventlog source, no need to set this for shared aka non-FI instances
    if (-not ([string]::IsNullOrWhiteSpace("${coreplatform_fi}"))) {
        Write-Msg "Set computer event source"
        [system.diagnostics.EventLog]::CreateEventSource("${coreplatform_fi}", "Application")
    }

    # Set the instance DNS address to the AD's DNS server, this is necessary to join the AD
    # but not necessary for FINSERV secure AD which must have routing rules that make this unnecessary
    if (-not ([string]::IsNullOrWhiteSpace($dnsServerAddresses))) {
        Write-Msg "Call Set-DnsClientServerAddress: $dnsServerAddresses"
        $ifIndex = (Get-NetAdapter | Where-Object InterfaceDescription -like "Amazon Elastic*" | Select-Object ifIndex).ifIndex
        Set-DnsClientServerAddress -InterfaceIndex $ifIndex -ServerAddresses ($dnsServerAddresses.Split(','))
    }

    Write-Msg "Get AD domain admin creds: $adUser"
    $adServiceuser = (Get-SECSecretValue -SecretId $adUser | Select-Object SecretString).SecretString
    Write-Msg "adServiceuser: $adServiceuser"
    $adPass = (Get-SECSecretValue -SecretId $adPassKey | Select-Object SecretString).SecretString | ConvertTo-SecureString -asPlainText -Force
    $credential = New-Object System.Management.Automation.PSCredential($adServiceuser,$adPass)

    # find available computer name using random digits if hostname has a placeholder
    Write-Msg "Rename computer, attempting to find an available computer name in AD $dnsDomain for: $hostname"
    $foundAvailableName = $false
    $tries = 0
    # if the hostname doesn't have the number placeholder just try this once, otherwise this be attempted numerous times
    $maxTries = If ($hostname -like '*000*') { 1000 } Else { 1 }
    do {
        $computerNum = ([string](Get-Random -Maximum 1000)).PadLeft(3, '0')
        $newComputerName = $hostname.Replace('000', $computerNum)
        try {
            Write-Msg "Check for computer: $newComputerName"
            Get-ADComputer $newComputerName -Credential $credential -Server $dnsDomain
            # if computer found no exception is thrown, try again
            Write-Msg "-- computer found in AD, search again"
            $tries++
        } 
        catch {
            # computer not found throws an exception
            Write-Msg $_
            Write-Msg "-- computer not found in AD, use this name for instance"
            $foundAvailableName = $true
        }
    } while ($foundAvailableName -ne $true -and $tries -lt $maxTries)

    # if no available computer name, exit out of script
    if ($foundAvailableName -ne $true) {
        Write-Msg "ERROR: No available computer name found in AD"
        exit 
    }

    Write-Msg "env:computername: $env:computername"
    Write-Msg "newComputerName: $newComputerName"
    
    Write-Msg "Update instance tag so Hostname contains the new computer name"
    $instance = Get-EC2Instance -InstanceId $instance_id
    foreach ($tag in $instance.instances[0].tags) {
        if ($tag.key -ceq "Hostname") {
            Remove-EC2Tag -Resource $instance_id -Tag $tag -Force
            New-EC2Tag -Resource $instance_id -Tag @{Key=$tag.key;Value=$newComputerName} -Force
        }
    }

    # Rename computer with retries in case Directory Service is Busy error occurs
    Write-Msg "Rename computer: $newComputerName"
    $tries = 1
    $maxTries = 10
    $computerRenamed = $false
    do {
        try {
            Write-Msg "Rename computer attempt: $tries"
            Rename-computer -ComputerName $env:computername -NewName $newComputerName -DomainCredential $credential -Force #-Restart
            $computerRenamed = $true
        } 
        catch {
            Write-Msg "Rename computer exception occurred: $_"
            $tries++
            Start-Sleep -Seconds 5
        }
    } while ($computerRenamed -ne $true -and $tries -lt $maxTries)

    # if computer was not renamed, exit out of script
    if ($computerRenamed -ne $true) {
        Write-Msg "ERROR: computer could not be renamed"
        exit 
    }

    # helps after rename
    Start-Sleep -Seconds 10

    # Add computer to AD
    Write-Msg "Add computer to AD: $env:computername, oupath: $oupath, dnsDomain: $dnsDomain"
    $tries = 1
    $maxTries = 10
    $domainJoined = $false
    do {
        try {
            Write-Msg "AD join attempt: $tries"
            Add-Computer -ComputerName $env:computername -DomainName $dnsDomain -Credential $credential -OUPath $oupath -Force -Options JoinWithNewName,AccountCreate -ErrorAction Stop
            $domainJoined = $true
        } 
        catch {
            Write-Msg "AD join exception occurred: $_"
            $tries++
            Start-Sleep -Seconds 5
        }
    } while ($domainJoined -ne $true -and $tries -lt $maxTries)

    # if computer did not join AD, exit out of script
    if ($domainJoined -ne $true) {
        Write-Msg "ERROR: computer did not join AD"
        exit 
    }

    # helps after AD join
    Start-Sleep -Seconds 60

    # additional GPO/roles
    Write-Msg "Checking GPOs: $env:GPO_PARAMS , DomainJoined: $domainJoined , computer name: $newComputerName"
    if ($domainJoined -and $null -ne $env:GPO_PARAMS -and $env:GPO_PARAMS -ne "") {
        foreach ($gpo in $env:GPO_PARAMS -split ",")
        {
            Write-Msg "Adding gpo: $gpo"
            if ($env:COREPLATFORM_ENV.ToLower() -match 'uat|prod') {
                Write-Msg "--using OU"
                Get-ADGroup -Server $dnsDomain -Credential $credential -SearchBase "OU=ENC-GRP,OU=ENC,OU=Servers,OU=FINSERVGlobal,DC=SECURE,DC=FINSERVGLOBAL,DC=COM" -Filter "name -eq '$gpo'" | Add-ADGroupMember -Members "$newComputerName$" -Credential $credential
            } else {
                Add-ADGroupMember -Identity "$gpo" -Members "$newComputerName$" -Credential $credential
            }
        }
    }

    # Clear config for Splunk now that we have a real hostname
    if (Test-Path "c:\program files\splunkuniversalforwarder\bin\splunk.exe") {
        Write-Msg "Clearing Splunk configuration"
        try
        {
            $splunkService = Get-Service -Name "SplunkForwarder"
            if ($splunkService.Status -eq "Running") {
                Stop-Service $splunkService
            }
        }
        catch { }

        Start-Process -FilePath "c:\program files\splunkuniversalforwarder\bin\splunk.exe" -ArgumentList "clone-prep-clear-config"
        Start-Process -FilePath "c:\program files\splunkuniversalforwarder\bin\splunk.exe" -ArgumentList "restart"
    }

    Write-Msg "Reenable Userdata to run on next reboot"
    C:\ProgramData\Amazon\EC2-Windows\Launch\Scripts\InitializeInstance.ps1 -Schedule

    #Write-Msg "Stopping transcript, forcing restart"
    Stop-Transcript

    # write out a file to indicate a restart has occurred
    Out-File -FilePath C:\work\restart.txt -Append

    Restart-Computer
}

</powershell>
<runAsLocalSystem>true</runAsLocalSystem>