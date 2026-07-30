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
$CommonApps = foreach ($app in ($_apps | Where-Object { -not $_.disabled })) {
  $customScript = ""
  if ($app.customScript) {
    $customScript = Join-Path $PSScriptRoot "../$($app.customScript)"
  }
  $deps = @()
  if ($app.dependencies) {
    $deps = @($app.dependencies)
  }
  @{
    Id             = $app.id
    Name           = $app.name
    Package        = $app.package
    PackageManager = $app.packageManager
    CustomScript   = $customScript
    Dependencies   = $deps
    InstallArgs    = @($app.installArgs)
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
    Write-Host ""

    for ($i = 0; $i -lt $script:Departments.Count; $i++)
    {
      $dept = $script:Departments[$i]
      $num = ($i + 1).ToString().PadLeft(2)
      Write-Host "  $num. $($dept.name)"
    }

    $customNum = $script:Departments.Count + 1
    $backNum   = $script:Departments.Count + 2
    Write-Host "  $($customNum.ToString().PadLeft(2)). Custom (Manual Selection)"
    Write-Divider
    Write-Host "  $($backNum.ToString().PadLeft(2)). Return to Main Menu"
    Write-Host ""
    Write-Host "  Selecting a profile presets apps & printers." -ForegroundColor Yellow
    Write-Footer

    $actionInput = (Read-Host "Choose (1-$backNum)").Trim()
    $val = 0

    if ([int]::TryParse($actionInput, [ref]$val))
    {
      if ($val -ge 1 -and $val -le $script:Departments.Count)
      {
        $dept = $script:Departments[$val - 1]
        Apply-DepartmentProfile $dept
        return
      } elseif ($val -eq $customNum)
      {
        $script:currentDepartmentName = "Custom"
        return
      } elseif ($val -eq $backNum)
      {
        return
      } else
      {
        Write-Host "Invalid option, press Enter to try again..." -ForegroundColor Red
        Read-Host | Out-Null
      }
    } else
    {
      Write-Host "Please enter a number only. Press Enter to try again..." -ForegroundColor Red
      Read-Host | Out-Null
    }
  }
}

function Start-Deployment
{
  Clear-Host
  $appsToInstall     = $CommonApps | Where-Object { $script:selectedApps[$_.Id] }

  if ($appsToInstall.Count -eq 0)
  {
    Write-Host "  No applications selected for installation." -ForegroundColor Yellow
    Show-PressEnterToContinue
    return
  }

  # --- Resolve dependencies: auto-add missing deps and reorder ---
  $selectedIds = [System.Collections.Generic.HashSet[string]]::new()
  foreach ($app in $appsToInstall) { $selectedIds.Add($app.Id) | Out-Null }

  # Find all missing dependencies and add them
  $depsAdded = @()
  foreach ($app in $appsToInstall)
  {
    foreach ($depId in $app.Dependencies)
    {
      if (-not $selectedIds.Contains($depId))
      {
        $selectedIds.Add($depId) | Out-Null
        $depsAdded += $depId
      }
    }
  }

  # Rebuild the install list: dependencies first, then the rest in original order
  if ($depsAdded.Count -gt 0)
  {
    $depApps = $CommonApps | Where-Object { $depsAdded -contains $_.Id }
    $appsToInstall = @($depApps) + @($appsToInstall)
  }
  else
  {
    # Even if no deps were missing, reorder so dependencies come before dependents
    $orderedList = [System.Collections.Generic.List[hashtable]]::new()
    $addedIds = [System.Collections.Generic.HashSet[string]]::new()
    foreach ($app in $appsToInstall)
    {
      # Add any dependencies of this app first (if not already added)
      foreach ($depId in $app.Dependencies)
      {
        if (-not $addedIds.Contains($depId))
        {
          $depApp = $CommonApps | Where-Object { $_.Id -eq $depId } | Select-Object -First 1
          if ($depApp) { $orderedList.Add($depApp); $addedIds.Add($depId) | Out-Null }
        }
      }
      # Add this app (if not already added as someone else's dependency)
      if (-not $addedIds.Contains($app.Id))
      {
        $orderedList.Add($app)
        $addedIds.Add($app.Id) | Out-Null
      }
    }
    $appsToInstall = $orderedList.ToArray()
  }

  # --- Confirm screen ---
  Write-Header "CONFIRM DEPLOYMENT"
  Write-Host "  Profile: $($script:currentDepartmentName)" -ForegroundColor Yellow
  Write-Host ""

  if ($appsToInstall.Count -gt 0)
  {
    Write-Host "  Applications to install:" -ForegroundColor Cyan
    foreach ($app in $appsToInstall)
    { Write-Host "    - $($app.Name)" }
  }

  Write-Divider
  Write-Host "  1. Start Deployment"
  Write-Host "  2. Cancel"
  Write-Footer

  $confirm = (Read-Host "Choose (1-2)").Trim()
  if ($confirm -ne "1")
  {
    Write-Host "  Deployment cancelled." -ForegroundColor Yellow
    Show-PressEnterToContinue
    return
  }

  # --- Track results ---
  $appResults     = [System.Collections.Generic.List[hashtable]]::new()

  Clear-Host
  Write-Header "DEPLOYMENT IN PROGRESS"
  Write-Host ""

  # Install Applications
  if ($appsToInstall.Count -gt 0)
  {
    Write-Host "  [*] Installing applications..." -ForegroundColor Cyan
    Write-Host ""
    foreach ($app in $appsToInstall)
    {
      Write-Host "  --> $($app.Name)..." -ForegroundColor Yellow -NoNewline
      $result = @{ Name = $app.Name; Status = ""; Error = "" }
      try
      {
        Install-App -Name $app.Name -PackageName $app.Package -PackageManager $app.PackageManager -CustomScript $app.CustomScript -InstallArgs $app.InstallArgs
        $result.Status = "OK"
        Write-Host " Done" -ForegroundColor Green
      } catch
      {
        $result.Status = "FAILED"
        $result.Error  = $_.Exception.Message
        Write-Host " FAILED" -ForegroundColor Red
        Write-Host "      $($_.Exception.Message)" -ForegroundColor DarkRed
      }
      $appResults.Add($result)
    }
  }



  # --- Summary Report ---
  Write-Host ""
  Write-Header "DEPLOYMENT SUMMARY"
  Write-Host "  Profile : $($script:currentDepartmentName)" -ForegroundColor Yellow
  Write-Host "  Finished: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Yellow
  Write-Host ""

  if ($appResults.Count -gt 0)
  {
    Write-Host "  APPLICATIONS" -ForegroundColor Cyan
    Write-Host "  ------------"
    foreach ($r in $appResults)
    {
      if ($r.Status -eq "OK")
      { Write-Host "  [ OK ]  $($r.Name)" -ForegroundColor Green }
      else
      {
        Write-Host "  [FAIL]  $($r.Name)" -ForegroundColor Red
        if ($r.Error) { Write-Host "          $($r.Error)" -ForegroundColor DarkRed }
      }
    }
    $okCount   = ($appResults | Where-Object { $_.Status -eq "OK" }).Count
    $failCount = $appResults.Count - $okCount
    Write-Host ""
    Write-Host "  Result: $okCount / $($appResults.Count) installed." -ForegroundColor $(if ($failCount -eq 0) { "Green" } else { "Yellow" })
  }



  Write-Host ""
  Write-Footer
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
    Write-Host " Selected: $appCount/$($CommonApps.Count) Apps"
    Write-Footer
    Write-Host "  1. Select User Department Profile"
    Write-Host "  2. Customize Selected Applications"
    Write-Host "  3. Customize Selected Printers  " -NoNewline
    Write-Host "(Coming Soon)" -ForegroundColor DarkGray
    Write-Host "  4. Collect User & System Information"
    Write-Host "  5. Start Deployment"
    Write-Host "  6. Exit"
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
