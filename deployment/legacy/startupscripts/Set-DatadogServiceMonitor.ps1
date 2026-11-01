function Set-DatadogServiceMonitor{
	param (
        $startup_params
    )

	
	if($startup_params.ContainsKey("datadog_service_monitor_prefix"))
	{
		$datadog_service_monitor_prefix = $startup_params["datadog_service_monitor_prefix"].toString() # "CoreService"

		Write-Host "DataDog: set windows service configuration prefix"
		$dd_fldr = "C:\ProgramData\Datadog\conf.d\windows_service.d"
		$dd_cfg= "$dd_fldr\conf.yaml"

		if (!(Test-Path -Path $dd_cfg -PathType Leaf)){
			Write-Host "Replace config.yaml: $dd_cfg"

			((Get-Content -path "$dd_cfg.example" -Raw) -replace "<SERVICE_NAME_1>","$datadog_service_monitor_prefix") | Set-Content -Path $dd_cfg

			((Get-Content -path "$dd_cfg" -Raw) -replace "- <SERVICE_NAME_2>","") | Set-Content -Path $dd_cfg

			Write-Host "DataDog: restart"
			Restart-Service -Name datadogagent -Force
		}
		else{
			Write-Host "$dd_cfg already exists, do nothing"
		}
	}
}