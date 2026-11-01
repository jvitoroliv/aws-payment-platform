Write-Host "Creating the Partner MQ Client config file"
$qmname	= $script_params_hash["qmname"]
$channel1 = $script_params_hash["channel1"]
$conname1 = $script_params_hash["conname1"]
$port1 = $script_params_hash["port1"]
$channel2 = $script_params_hash["channel2"]
$conname2 = $script_params_hash["conname2"]
$port2 = $script_params_hash["port2"]

# if qmname is not populated, assume no TAB file needs to be generated (this will happen in envs that don't access Partner MQ, e.g., Dev/QA)
if (-Not ([string]::IsNullOrEmpty($qmname))) {
    $env = $env:COREPLATFORM_ENV

	$mqFolder = "C:\CorePlatform\PartnerMQ"
	New-Item -ItemType Directory -Force -Path $mqFolder
	
	$websphereMqFolder = "C:\Program Files\IBM\MQ"
	$websphereTabFileName = "AMQCLCHL.TAB"
    $websphereTabFileNameJson = "CorePlatformAWS-IBM-MQ-CCDT.json"

    #BEGIN: Get JSON MQ Client Config File
    $localJsonFileName = Join-Path $websphereMqFolder $websphereTabFileNameJson
    if (!(Test-Path $localJsonFileName)) {
        try {
            Read-S3Object -BucketName "platform-artifacts-$env".ToLower() -Key "$websphereTabFileNameJson" -File "$localJsonFileName"
        } catch {
            Write-Host "Error attempting to write the JSON file from an S3 bucket: $_.Exception.Message"
        }
    }
    #END: Get JSON MQ Client Config File

    # MQ client requires these env vars in order to find the TAB or JSON file
	[System.Environment]::SetEnvironmentVariable('MQCHLLIB', $websphereMqFolder, [System.EnvironmentVariableTarget]::Machine)

    #Below determines if the MQ Client will use the JSON file or TAB file for it's load balancing configuration
    if ($env -match "uat") {
    	[System.Environment]::SetEnvironmentVariable('MQCHLTAB', $websphereTabFileNameJson, [System.EnvironmentVariableTarget]::Machine)
    } else {
        [System.Environment]::SetEnvironmentVariable('MQCHLTAB', $websphereTabFileName, [System.EnvironmentVariableTarget]::Machine)
    }

	# Even though the env vars are set at the machine level above, they need to be set for this process in order for runmqsc to access them below
	$env:MQCHLLIB = $websphereMqFolder
	$env:MQCHLTAB = $websphereTabFileName
	
	$runmqscExe = "$env:MQCHLLIB\bin\runmqsc.exe"
	
    #BEGIN: Build the TAB configuration file
	Write-Host "-- Writing buildchannels.txt file"
	$buildChannels = @(
	"DEFINE CHANNEL ($channel1) CHLTYPE(CLNTCONN) CONNAME('$conname1($port1)') QMNAME($qmname) AFFINITY(NONE) CLNTWGHT(50) SHARECNV(0)",
	"DEFINE CHANNEL ($channel2) CHLTYPE(CLNTCONN) CONNAME('$conname2($port2)') QMNAME($qmname) AFFINITY(NONE) CLNTWGHT(50) SHARECNV(0)"
	)
	[System.IO.File]::WriteAllLines("$mqFolder\buildchannels.txt", $buildChannels)
	Write-Host "-- Creating AMQCLCHL.TAB file"
	cmd.exe /c $runmqscExe -n '<' "$mqFolder\buildchannels.txt"
	
	# Write out contents of TAB file in case anyone wants to see how its been set on this instance
	[System.IO.File]::WriteAllLines("$mqFolder\getchannels.txt", "DISPLAY CHANNEL(*) ALL")
	Write-Host "-- Writing AMQCLCHL.TAB info file"
	cmd.exe /c $runmqscExe -n '<' "$mqFolder\getchannels.txt" '>' "$mqFolder\AMQCLCHL.TAB.txt"
	#END: Build the TAB configuration file

	$programDataFolder = "C:\ProgramData\IBM\MQ"
	if (Test-Path $programDataFolder) {
		Write-Host "Copy AMQCLCHL.TAB to ProgramData for use until reboot occurs"
		Copy-Item "$websphereMqFolder\$websphereTabFileName" -Destination $programDataFolder
		
        if (Test-Path $websphereMqFolder\$websphereTabFileNameJson) {
            Write-Host "Copy CorePlatformAWS-IBM-MQ-CCDT.json to ProgramData for use until reboot occurs"
		    Copy-Item "$websphereMqFolder\$websphereTabFileNameJson" -Destination $programDataFolder
        }
	}
}
