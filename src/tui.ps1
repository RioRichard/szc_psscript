# SZC Automated Deployment TUI

# Load necessary modules and configurations
. "$PSScriptRoot/install_commonapp.ps1"
. "$PSScriptRoot/printers_dn.ps1"

# Define user departments and their recommended installations
$script:Departments = @(
  @{
    Name = "Ban Giam Doc (Directors)"
    Apps = @("Microsoft Office", "Viber", "Zalo", "Chrome", "Microsoft OneDrive", "UniKey", "Kaspersky Endpoint Security")
    Printers = @("HP 4003 DN", "Ricoh MP 3555 BH (Photocopy)")
  },
  @{
    Name = "Ke Toan (Accounting)"
    Apps = @("Microsoft Office", "Viber", "Zalo", "Chrome", "Microsoft OneDrive", "UniKey", "Kaspersky Endpoint Security", "VCRedist (x64)", "VCRedist (x86)")
    Printers = @("Brother T4500DW BH", "Ricoh MP 3555 BH (Photocopy)")
  },
  @{
    Name = "Hanh Chinh Nhan Su (HR & Admin)"
    Apps = @("Microsoft Office", "Viber", "Zalo", "Chrome", "Microsoft OneDrive", "UniKey", "Kaspersky Endpoint Security", "7 Zip", "Ultra Viewer")
    Printers = @("EPSON L1800 BH", "Ricoh MP 3555 BH (Photocopy)")
  },
  @{
    Name = "Kinh Doanh (Sales / Marketing)"
    Apps = @("Microsoft Office", "Viber", "Zalo", "Chrome", "Microsoft OneDrive", "UniKey", "Kaspersky Endpoint Security")
    Printers = @("Ricoh MP 3555 BH (Photocopy)")
  },
  @{
    Name = "Ky Thuat (IT / Tech)"
    Apps = @("UniKey", "Viber", "Zalo", "Microsoft Office", "Kaspersky Endpoint Security", "Microsoft OneDrive", "Ultra Viewer", "Chrome", "7 Zip", "VCRedist (x64)", "VCRedist (x86)")
    Printers = @("HP 4003 DN", "Brother T4500DW BH", "Ricoh MP 3555 BH (Photocopy)", "EPSON L1800 BH")
  }
)

# Initialize selection states
$script:selectedApps = @{}
$script:selectedPrinters = @{}
$script:currentDepartmentName = "Ky Thuat (IT / Tech)"

# Function to apply department profile
function Apply-DepartmentProfile ($dept)
{
  # Deselect all
  foreach ($app in $CommonApps)
  {
    $script:selectedApps[$app.Name] = $false
  }
  foreach ($printer in $Printers)
  {
    $script:selectedPrinters[$printer.Name] = $false
  }
  
  # Select profile specifics
  foreach ($appName in $dept.Apps)
  {
    $script:selectedApps[$appName] = $true
  }
  foreach ($printerName in $dept.Printers)
  {
    $script:selectedPrinters[$printerName] = $true
  }
  
  $script:currentDepartmentName = $dept.Name
}

# Apply default profile (Ky Thuat) on startup
$defaultDept = $script:Departments | Where-Object { $_.Name -like "*Ky Thuat*" }
if ($defaultDept)
{
  Apply-DepartmentProfile $defaultDept
} else
{
  Apply-DepartmentProfile $script:Departments[0]
}

function Show-DepartmentMenu
{
  while ($true)
  {
    Clear-Host
    Write-Host "==================================================" -ForegroundColor Cyan
    Write-Host "         SELECT USER DEPARTMENT PROFILE           " -ForegroundColor Green
    Write-Host "==================================================" -ForegroundColor Cyan
    
    for ($i = 0; $i -lt $script:Departments.Count; $i++)
    {
      $dept = $script:Departments[$i]
      $num = $i + 1
      Write-Host "  [$num] $($dept.Name)"
    }
    Write-Host "  [C] Custom (Manual Selection)"
    Write-Host "  [Q] Return to Main Menu"
    Write-Host "--------------------------------------------------"
    Write-Host "Selecting a profile presets apps & printers." -ForegroundColor Yellow
    Write-Host "==================================================" -ForegroundColor Cyan
    
    $actionInput = (Read-Host "Choose profile").Trim().ToUpper()
    
    if ($actionInput -eq "Q")
    {
      return
    } elseif ($actionInput -eq "C")
    {
      $script:currentDepartmentName = "Custom"
      return
    } else
    {
      $val = 0
      if ([int]::TryParse($actionInput, [ref]$val) -and $val -ge 1 -and $val -le $script:Departments.Count)
      {
        $dept = $script:Departments[$val - 1]
        Apply-DepartmentProfile $dept
        return
      } else
      {
        Write-Host "Invalid option, press Enter to try again..." -ForegroundColor Red
        Read-Host | Out-Null
      }
    }
  }
}

function Show-AppSelectionMenu
{
  while ($true)
  {
    Clear-Host
    Write-Host "==================================================" -ForegroundColor Cyan
    Write-Host "          SELECT APPLICATIONS TO INSTALL          " -ForegroundColor Green
    Write-Host "==================================================" -ForegroundColor Cyan
    
    for ($i = 0; $i -lt $CommonApps.Count; $i++)
    {
      $app = $CommonApps[$i]
      $checkbox = if ($script:selectedApps[$app.Name])
      { "[X]" 
      } else
      { "[ ]" 
      }
      $num = ($i + 1).ToString().PadLeft(2)
      Write-Host "  $num. $checkbox $($app.Name)"
    }
    
    Write-Host "--------------------------------------------------"
    Write-Host "  Enter a number (1-$($CommonApps.Count)) to toggle"
    Write-Host "  Enter 'A' to select All, 'N' to select None"
    Write-Host "  Enter 'Q' to Return to Main Menu"
    Write-Host "==================================================" -ForegroundColor Cyan
    
    $actionInput = (Read-Host "Action").Trim().ToUpper()
    
    if ($actionInput -eq "Q")
    {
      return
    } elseif ($actionInput -eq "A")
    {
      foreach ($app in $CommonApps)
      { $script:selectedApps[$app.Name] = $true 
      }
      $script:currentDepartmentName = "Custom"
    } elseif ($actionInput -eq "N")
    {
      foreach ($app in $CommonApps)
      { $script:selectedApps[$app.Name] = $false 
      }
      $script:currentDepartmentName = "Custom"
    } else
    {
      $val = 0
      if ([int]::TryParse($actionInput, [ref]$val) -and $val -ge 1 -and $val -le $CommonApps.Count)
      {
        $app = $CommonApps[$val - 1]
        $script:selectedApps[$app.Name] = !$script:selectedApps[$app.Name]
        $script:currentDepartmentName = "Custom"
      } else
      {
        Write-Host "Invalid option, press Enter to try again..." -ForegroundColor Red
        Read-Host | Out-Null
      }
    }
  }
}

function Show-PrinterSelectionMenu
{
  while ($true)
  {
    Clear-Host
    Write-Host "==================================================" -ForegroundColor Cyan
    Write-Host "            SELECT PRINTERS TO INSTALL            " -ForegroundColor Green
    Write-Host "==================================================" -ForegroundColor Cyan
    
    for ($i = 0; $i -lt $Printers.Count; $i++)
    {
      $printer = $Printers[$i]
      $checkbox = if ($script:selectedPrinters[$printer.Name])
      { "[X]" 
      } else
      { "[ ]" 
      }
      $num = ($i + 1).ToString().PadLeft(2)
      Write-Host "  $num. $checkbox $($printer.Name) ($($printer.Url))"
    }
    
    Write-Host "--------------------------------------------------"
    Write-Host "  Enter a number (1-$($Printers.Count)) to toggle"
    Write-Host "  Enter 'A' to select All, 'N' to select None"
    Write-Host "  Enter 'Q' to Return to Main Menu"
    Write-Host "==================================================" -ForegroundColor Cyan
    
    $actionInput = (Read-Host "Action").Trim().ToUpper()
    
    if ($actionInput -eq "Q")
    {
      return
    } elseif ($actionInput -eq "A")
    {
      foreach ($printer in $Printers)
      { $script:selectedPrinters[$printer.Name] = $true 
      }
      $script:currentDepartmentName = "Custom"
    } elseif ($actionInput -eq "N")
    {
      foreach ($printer in $Printers)
      { $script:selectedPrinters[$printer.Name] = $false 
      }
      $script:currentDepartmentName = "Custom"
    } else
    {
      $val = 0
      if ([int]::TryParse($actionInput, [ref]$val) -and $val -ge 1 -and $val -le $Printers.Count)
      {
        $printer = $Printers[$val - 1]
        $script:selectedPrinters[$printer.Name] = !$script:selectedPrinters[$printer.Name]
        $script:currentDepartmentName = "Custom"
      } else
      {
        Write-Host "Invalid option, press Enter to try again..." -ForegroundColor Red
        Read-Host | Out-Null
      }
    }
  }
}

function Get-SystemInformation
{
  Clear-Host
  Write-Host "==================================================" -ForegroundColor Cyan
  Write-Host "            COLLECTING SYSTEM INFORMATION          " -ForegroundColor Green
  Write-Host "==================================================" -ForegroundColor Cyan
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
    
    Write-Host "--------------------------------------------------"
    
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
  
  Write-Host "==================================================" -ForegroundColor Cyan
  Write-Host "Press Enter to return to main menu..."
  Read-Host | Out-Null
}

function Start-Deployment
{
  Clear-Host
  $appsToInstall = $CommonApps | Where-Object { $script:selectedApps[$_.Name] }
  $printersToInstall = $Printers | Where-Object { $script:selectedPrinters[$_.Name] }
  
  if ($appsToInstall.Count -eq 0 -and $printersToInstall.Count -eq 0)
  {
    Write-Host "No applications or printers selected for installation." -ForegroundColor Yellow
    Write-Host "Press Enter to return to main menu..."
    Read-Host | Out-Null
    return
  }
  
  Write-Host "==================================================" -ForegroundColor Cyan
  Write-Host "               CONFIRM DEPLOYMENT                 " -ForegroundColor Green
  Write-Host "==================================================" -ForegroundColor Cyan
  Write-Host " Profile Selected: $($script:currentDepartmentName)" -ForegroundColor Yellow
  Write-Host ""
  
  if ($appsToInstall.Count -gt 0)
  {
    Write-Host " Applications to install:" -ForegroundColor Yellow
    foreach ($app in $appsToInstall)
    {
      Write-Host "   - $($app.Name)"
    }
  }
  if ($printersToInstall.Count -gt 0)
  {
    Write-Host " Printers to install:" -ForegroundColor Yellow
    foreach ($printer in $printersToInstall)
    {
      Write-Host "   - $($printer.Name)"
    }
  }
  Write-Host "==================================================" -ForegroundColor Cyan
  
  $confirm = (Read-Host "Do you want to proceed with installation? (Y/N)").Trim().ToUpper()
  if ($confirm -ne "Y")
  {
    Write-Host "Deployment cancelled." -ForegroundColor Yellow
    Write-Host "Press Enter to return to main menu..."
    Read-Host | Out-Null
    return
  }
  
  Clear-Host
  Write-Host "==================================================" -ForegroundColor Cyan
  Write-Host "            DEPLOYMENT IN PROGRESS                " -ForegroundColor Green
  Write-Host "==================================================" -ForegroundColor Cyan
  Write-Host ""
  
  # Install Applications
  if ($appsToInstall.Count -gt 0)
  {
    Write-Host "[*] Starting application installations..." -ForegroundColor Cyan
    foreach ($app in $appsToInstall)
    {
      Write-Host "Installing: $($app.Name)..." -ForegroundColor Yellow
      
      try
      {
        Install-App -Name $app.Name -PackageName $app.Package -PackageManager $app.PackageManager -Custom $app.Custom
        Write-Host "[+] $($app.Name) completed successfully!" -ForegroundColor Green
      } catch
      {
        Write-Host "[-] Failed to install $($app.Name): $($_.Exception.Message)" -ForegroundColor Red
      }
      Write-Host ""
    }
  }
  
  # Install Printers
  if ($printersToInstall.Count -gt 0)
  {
    Write-Host "[*] Starting printer installations..." -ForegroundColor Cyan
    foreach ($printer in $printersToInstall)
    {
      Write-Host "Installing: $($printer.Name)..." -ForegroundColor Yellow
      
      try
      {
        Install-LocalPrinter -Name $printer.Name -Url $printer.Url -Port $printer.Port -Driver $printer.Driver -UrlDriver $printer.UrlDriver
        Write-Host "[+] $($printer.Name) completed successfully!" -ForegroundColor Green
      } catch
      {
        Write-Host "[-] Failed to install $($printer.Name): $($_.Exception.Message)" -ForegroundColor Red
      }
      Write-Host ""
    }
  }
  
  Write-Host "==================================================" -ForegroundColor Cyan
  Write-Host "               DEPLOYMENT FINISHED                " -ForegroundColor Green
  Write-Host "==================================================" -ForegroundColor Cyan
  Write-Host "Press Enter to return to main menu..."
  Read-Host | Out-Null
}

function Show-MainMenu
{
  while ($true)
  {
    Clear-Host
    Write-Host "==================================================" -ForegroundColor Cyan
    Write-Host "          SZC AUTOMATED DEPLOYMENT TOOL           " -ForegroundColor Green
    Write-Host "==================================================" -ForegroundColor Cyan
    Write-Host " Active Profile: $($script:currentDepartmentName)" -ForegroundColor Yellow
    
    # Show active count summaries
    $appCount = ($script:selectedApps.Values | Where-Object { $_ }).Count
    $printerCount = ($script:selectedPrinters.Values | Where-Object { $_ }).Count
    Write-Host " Selected: $appCount/$($CommonApps.Count) Apps, $printerCount/$($Printers.Count) Printers"
    Write-Host "==================================================" -ForegroundColor Cyan
    Write-Host " [1] Select User Department Profile"
    Write-Host " [2] Customize Selected Applications"
    Write-Host " [3] Customize Selected Printers"
    Write-Host " [4] Collect User & System Information"
    Write-Host " [5] Start Deployment"
    Write-Host " [6] Exit"
    Write-Host "==================================================" -ForegroundColor Cyan
    Write-Host ""
    
    $choice = (Read-Host "Choose an option (1-6)").Trim()
    
    switch ($choice)
    {
      "1"
      { Show-DepartmentMenu 
      }
      "2"
      { Show-AppSelectionMenu 
      }
      "3"
      { Show-PrinterSelectionMenu 
      }
      "4"
      { Get-SystemInformation 
      }
      "5"
      { Start-Deployment 
      }
      "6"
      { 
        Write-Host "Exiting. Goodbye!" -ForegroundColor Yellow
        return
      }
      default
      {
        Write-Host "Invalid choice, press Enter to try again..." -ForegroundColor Red
        Read-Host | Out-Null
      }
    }
  }
}

function Start-Tui
{
  Show-MainMenu
}
