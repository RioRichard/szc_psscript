function Get-SystemInformation
{
  Clear-Host
  Write-Header "COLLECTING SYSTEM INFORMATION"
  Write-Host ""
  
  try
  {
    $os = Get-CimInstance Win32_OperatingSystem -ErrorAction Stop
    $cpu = Get-CimInstance Win32_Processor -ErrorAction Stop
    $cs = Get-CimInstance Win32_ComputerSystem -ErrorAction Stop
    $ramGB = [Math]::Round((Get-CimInstance Win32_PhysicalMemory -ErrorAction SilentlyContinue | Measure-Object Capacity -Sum).Sum / 1GB, 2)
    $disks = (Get-CimInstance Win32_LogicalDisk | Where-Object DriveType -eq 3 | ForEach-Object { "$($_.DeviceID) (Free: $([Math]::Round($_.FreeSpace / 1GB, 1)) GB / Total: $([Math]::Round($_.Size / 1GB, 1)) GB)" }) -join ", "
    $ips = (Get-NetIPAddress -AddressFamily IPv4 -InterfaceAlias "Wi-Fi", "Ethernet" -ErrorAction SilentlyContinue | Select-Object -ExpandProperty IPAddress) -join ", "
    $macs = (Get-NetAdapter | Where-Object Status -eq "Up" | Select-Object -ExpandProperty MacAddress -ErrorAction SilentlyContinue) -join ", "
    
    $sysInfo = [ordered]@{
      "Computer Name"   = $env:COMPUTERNAME
      "Current User"    = "$env:USERDOMAIN\$env:USERNAME"
      "OS Version"      = $os.Caption
      "OS Build"        = $os.Version
      "Architecture"    = $os.OSArchitecture
      "CPU"             = $cpu.Name
      "RAM Capacity"    = "$ramGB GB"
      "Disk Space"      = $disks
      "IP Address"      = $ips
      "MAC Address"     = $macs
      "Domain/Workgroup"= $cs.Domain
    }

    foreach ($key in $sysInfo.Keys)
    {
      Write-Host "$($key.PadRight(18)): $($sysInfo[$key])" -ForegroundColor Yellow
    }
    
    Write-Divider
    
    $destDir = "C:\ProgramData\SZC"
    if (!(Test-Path $destDir))
    {
      New-Item -ItemType Directory -Path $destDir -Force | Out-Null
    }
    $destFile = Join-Path $destDir "SystemInfo_$($env:COMPUTERNAME).txt"
    
    $report = New-Object System.Text.StringBuilder
    $report.AppendLine("==================================================") | Out-Null
    $report.AppendLine("            SYSTEM INFORMATION REPORT             ") | Out-Null
    $report.AppendLine("==================================================") | Out-Null
    foreach ($key in $sysInfo.Keys)
    {
      $report.AppendLine("$($key.PadRight(18)): $($sysInfo[$key])") | Out-Null
    }
    $report.AppendLine("==================================================") | Out-Null
    
    $report.ToString() | Out-File -FilePath $destFile -Force
    
    Write-Host "Report saved to: $destFile" -ForegroundColor Green
  } catch
  {
    Write-Error "Failed to retrieve system information: $($_.Exception.Message)"
  }
  
  Write-Footer
  Show-PressEnterToContinue
}
