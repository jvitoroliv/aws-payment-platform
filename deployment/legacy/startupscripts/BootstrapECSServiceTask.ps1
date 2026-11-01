# Bootstrap the container with networking commands for IAM roles for tasks
# https://docs.aws.amazon.com/AmazonECS/latest/developerguide/windows_task_IAM_roles.html

Write-Output "Bootstrap starts"

$gateway = (Get-NetRoute | Where-Object { $_.DestinationPrefix -eq '0.0.0.0/0' } | Sort-Object RouteMetric | Select-Object NextHop).NextHop
Write-Output "Bootstrap gateway: $gateway"

$ifIndex = (Get-NetAdapter -InterfaceDescription "Hyper-V Virtual Ethernet*" | Sort-Object | Select-Object ifIndex).ifIndex
Write-Output "Bootstrap ifIndex: $ifIndex"

New-NetRoute -DestinationPrefix 169.254.170.2/32 -InterfaceIndex $ifIndex -NextHop $gateway

Write-Output "Bootstrap complete"
