# SZC Automated Deployment TUI - Coordinator

# Load helper installer scripts
. (Join-Path $PSScriptRoot "../app/install_app.ps1")
. (Join-Path $PSScriptRoot "../printer/install_printer.ps1")

# Load configuration paths
$appsJsonPath = Join-Path $PSScriptRoot "../config/apps.json"
$printersJsonPath = Join-Path $PSScriptRoot "../config/printers.json"
$departmentsJsonPath = Join-Path $PSScriptRoot "../config/departments.json"

# Parse application definitions
$_apps = Get-Content $appsJsonPath -Raw | ConvertFrom-Json
$CommonApps = foreach ($app in $_apps) {
  $custom = ""
  if ($app.customScript) {
    $scriptPath = Join-Path $PSScriptRoot "../$($app.customScript)"
    $custom = @("-ExecutionPolicy", "ByPass", $scriptPath)
  }
  @{
    Id             = $app.id
    Name           = $app.name
    Package        = $app.package
    PackageManager = $app.packageManager
    Custom         = $custom
  }
}

# Parse printer definitions
$_printers = Get-Content $printersJsonPath -Raw | ConvertFrom-Json
$Printers = foreach ($printer in $_printers) {
  @{
    Id        = $printer.id
    Name      = $printer.name
    Url       = $printer.url
    Port      = $printer.port
    Driver    = $printer.driver
    UrlDriver = $printer.urlDriver
  }
}

# Load department profiles
$script:Departments = Get-Content $departmentsJsonPath -Raw | ConvertFrom-Json

# Load sub-components
. (Join-Path $PSScriptRoot "components/utils.ps1")
. (Join-Path $PSScriptRoot "app/app_ui.ps1")
. (Join-Path $PSScriptRoot "printer/printer_ui.ps1")
. (Join-Path $PSScriptRoot "information/info_ui.ps1")

# Initialize selection states
$script:selectedApps = @{}
$script:selectedPrinters = @{}
$script:currentDepartmentName = ""

# Function to apply department profile
function Apply-DepartmentProfile ($dept)
{
  # Deselect all
  foreach ($app in $CommonApps)
  {
    $script:selectedApps[$app.Id] = $false
  }
  foreach ($printer in $Printers)
  {
    $script:selectedPrinters[$printer.Id] = $false
  }
  
  # Select profile specifics
  foreach ($appId in $dept.apps)
  {
    $script:selectedApps[$appId] = $true
  }
  foreach ($printerId in $dept.printers)
  {
    $script:selectedPrinters[$printerId] = $true
  }
  
  $script:currentDepartmentName = $dept.name
}

# Apply default profile (Ky Thuat) on startup if exists, otherwise first profile
$defaultDept = $script:Departments | Where-Object { $_.id -eq "it_tech" -or $_.name -like "*Ky Thuat*" }
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
    Write-Header "SELECT USER DEPARTMENT PROFILE"
    
    for ($i = 0; $i -lt $script:Departments.Count; $i++)
    {
      $dept = $script:Departments[$i]
      $num = $i + 1
      Write-Host "  [$num] $($dept.name)"
    }
    Write-Host "  [C] Custom (Manual Selection)"
    Write-Host "  [Q] Return to Main Menu"
    Write-Divider
    Write-Host "Selecting a profile presets apps & printers." -ForegroundColor Yellow
    Write-Footer
    
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

function Start-Deployment
{
  Clear-Host
  $appsToInstall = $CommonApps | Where-Object { $script:selectedApps[$_.Id] }
  $printersToInstall = $Printers | Where-Object { $script:selectedPrinters[$_.Id] }
  
  if ($appsToInstall.Count -eq 0 -and $printersToInstall.Count -eq 0)
  {
    Write-Host "No applications or printers selected for installation." -ForegroundColor Yellow
    Show-PressEnterToContinue
    return
  }
  
  Write-Header "CONFIRM DEPLOYMENT"
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
  
  Write-Footer
  
  $confirm = (Read-Host "Do you want to proceed with installation? (Y/N)").Trim().ToUpper()
  if ($confirm -ne "Y")
  {
    Write-Host "Deployment cancelled." -ForegroundColor Yellow
    Show-PressEnterToContinue
    return
  }
  
  Clear-Host
  Write-Header "DEPLOYMENT IN PROGRESS"
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
  
  Write-Header "DEPLOYMENT FINISHED"
  Show-PressEnterToContinue
}

function Show-MainMenu
{
  while ($true)
  {
    Clear-Host
    Write-Header "SZC AUTOMATED DEPLOYMENT TOOL"
    Write-Host " Active Profile: $($script:currentDepartmentName)" -ForegroundColor Yellow
    
    # Show active count summaries
    $appCount = ($script:selectedApps.Values | Where-Object { $_ }).Count
    $printerCount = ($script:selectedPrinters.Values | Where-Object { $_ }).Count
    Write-Host " Selected: $appCount/$($CommonApps.Count) Apps, $printerCount/$($Printers.Count) Printers"
    Write-Footer
    Write-Host " [1] Select User Department Profile"
    Write-Host " [2] Customize Selected Applications"
    Write-Host " [3] Customize Selected Printers"
    Write-Host " [4] Collect User & System Information"
    Write-Host " [5] Start Deployment"
    Write-Host " [6] Exit"
    Write-Footer
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
