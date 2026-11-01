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

Set-ExecutionPolicy unrestricted -Scope CurrentUser -Force
Set-TimeZone "Eastern Standard Time"
New-Item -ItemType directory -Path C:\work -Force
Start-Transcript -Path C:\work\userdata.log -Append

$timestamp = Get-Date
Write-Msg "Instance Start $timestamp"

if ((Get-WmiObject win32_computersystem).partofdomain) {
    #sync time with DC
    Write-Msg "Sync the clock to domain controller"
    w32tm /config /syncfromflags:domhier
    net stop w32time
    net start w32time
    w32tm /resync

    Write-Msg "gpupdate"
    gpupdate /force
}

# Run startup script on server
if (-not ([string]::IsNullOrWhiteSpace("${startup_script}"))) {
    Write-Msg "Running startup script: ${startup_script} ${startup_script_params}"
    Set-Location ${startup_path}
    .\${startup_script} ${startup_script_params}
    Write-Msg "Startup script complete"
} else {
    Write-Msg "No startup script specified"
}

Write-Msg "Done"

</powershell>
<runAsLocalSystem>true</runAsLocalSystem>