<powershell>
$testchoco = powershell choco -v

if(!($testchoco))
    {
        Write-Host "Chocolatey is not installed.  Please run the Chocolatey install then try this install again."
        Exit -1
    }
try
    {
        # auto-registration doesn't seem to work.  Attempt manual like normal common ec2 userdata
        choco upgrade TrendMicro #--params="'/Register:true'" -y --force
        Set-Location -Path "C:\Program Files\Trend Micro\Deep Security Agent\"
        .\dsa_control.cmd -r
        .\dsa_control.cmd -a dsm://agents.deepsecurity.trendmicro.com:443/ "tenantID:XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX" "token:YYYYYYYY-YYYY-YYYY-YYYY-YYYYYYYYYYYY" "policyid:0000"
        Restart-Service ds_agent
    }
catch
    {
        Write-Host "TrendMicro install failed"
        Write-Host $_.Exception.Message
        Exit -1
    }
</powershell>