# SZC PowerShell Script Suite - Bundler Script
# This script bundles all src/ components, config JSONs, installer scripts,
# and static assets into a single standalone file: dist/szc_setup_bundled.ps1

$ErrorActionPreference = "Stop"

$repoRoot = $PSScriptRoot
if (-not $repoRoot) { $repoRoot = Get-Location }

$distDir = Join-Path $repoRoot "dist"
if (-not (Test-Path $distDir)) {
    New-Item -ItemType Directory -Path $distDir -Force | Out-Null
}

$outputFile = Join-Path $distDir "szc_setup_bundled.ps1"

Write-Host "Packing SZC script suite into single file..." -ForegroundColor Cyan

# Function to safely quote string for single-quoted Here-String
function Format-HereString([string]$content) {
    return "@'`n" + $content.Trim() + "`n'@"
}

# 1. Read JSON Configs
$appsJson        = Get-Content (Join-Path $repoRoot "src/config/apps.json") -Raw
$printersJson    = Get-Content (Join-Path $repoRoot "src/config/printers.json") -Raw
$departmentsJson = Get-Content (Join-Path $repoRoot "src/config/departments.json") -Raw

# 2. Read Assets
$officeCustomXml = Get-Content (Join-Path $repoRoot "src/app/office_install/OfficeCustom.xml") -Raw

# 3. Read Helper Scripts
$downloadHelper  = Get-Content (Join-Path $repoRoot "src/app/download_helper.ps1") -Raw
$installPrinter  = Get-Content (Join-Path $repoRoot "src/printer/install_printer.ps1") -Raw

# 4. Read Custom Install Scripts
$officeInstallScript  = Get-Content (Join-Path $repoRoot "src/app/office_install/install.ps1") -Raw
$kesInstallScript     = Get-Content (Join-Path $repoRoot "src/app/kes_install/install.ps1") -Raw
$bnscInstallScript    = Get-Content (Join-Path $repoRoot "src/app/bnsc_install/install.ps1") -Raw
$lockxlsInstallScript = Get-Content (Join-Path $repoRoot "src/app/lockxls_install/install.ps1") -Raw
$autocadInstallScript = Get-Content (Join-Path $repoRoot "src/app/autocad_install/install.ps1") -Raw
$netfx35InstallScript = Get-Content (Join-Path $repoRoot "src/app/netfx35_install/install.ps1") -Raw

# 5. Read TUI components
$tuiUtils   = Get-Content (Join-Path $repoRoot "src/tui/components/utils.ps1") -Raw
$tuiApp     = Get-Content (Join-Path $repoRoot "src/tui/app/app_ui.ps1") -Raw
$tuiPrinter = Get-Content (Join-Path $repoRoot "src/tui/printer/printer_ui.ps1") -Raw
$tuiInfo    = Get-Content (Join-Path $repoRoot "src/tui/information/info_ui.ps1") -Raw

# 6. Assemble the single script
$sb = [System.Text.StringBuilder]::new()

[void]$sb.AppendLine("# ==========================================================================")
[void]$sb.AppendLine("# SZC AUTOMATED DEPLOYMENT SUITE - STANDALONE BUNDLED SCRIPT")
[void]$sb.AppendLine("# Built on: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')")
[void]$sb.AppendLine("# ==========================================================================")
[void]$sb.AppendLine("")

# Auto elevation check
[void]$sb.AppendLine('# --- Ensure Administrator Privileges ---')
[void]$sb.AppendLine('if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator"))')
[void]$sb.AppendLine('{')
[void]$sb.AppendLine('  Write-Host "This tool requires Administrator privileges. Requesting elevation..." -ForegroundColor Yellow')
[void]$sb.AppendLine('  try')
[void]$sb.AppendLine('  {')
[void]$sb.AppendLine('    Start-Process powershell.exe `')
[void]$sb.AppendLine('      -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" `')
[void]$sb.AppendLine('      -Verb RunAs')
[void]$sb.AppendLine('  }')
[void]$sb.AppendLine('  catch')
[void]$sb.AppendLine('  {')
[void]$sb.AppendLine('    Write-Host "Failed to elevate: $($_.Exception.Message)" -ForegroundColor Red')
[void]$sb.AppendLine('    Write-Host "Please right-click PowerShell and select ' + "'Run as Administrator'" + '." -ForegroundColor Yellow')
[void]$sb.AppendLine('    Read-Host "Press Enter to exit"')
[void]$sb.AppendLine('  }')
[void]$sb.AppendLine('  exit')
[void]$sb.AppendLine('}')
[void]$sb.AppendLine("")

# Embed JSON files
[void]$sb.AppendLine('# --- EMBEDDED CONFIGURATIONS & ASSETS ---')
[void]$sb.AppendLine('$script:Embedded_AppsJson = ' + (Format-HereString $appsJson))
[void]$sb.AppendLine('$script:Embedded_PrintersJson = ' + (Format-HereString $printersJson))
[void]$sb.AppendLine('$script:Embedded_DepartmentsJson = ' + (Format-HereString $departmentsJson))
[void]$sb.AppendLine('$script:Embedded_OfficeCustomXml = ' + (Format-HereString $officeCustomXml))
[void]$sb.AppendLine("")

# Embed Helper Scripts
[void]$sb.AppendLine('# --- DOWNLOAD HELPER ---')
[void]$sb.AppendLine($downloadHelper)
[void]$sb.AppendLine("")

[void]$sb.AppendLine('# --- PRINTER INSTALLER ---')
[void]$sb.AppendLine($installPrinter)
[void]$sb.AppendLine("")

# Custom installers table
[void]$sb.AppendLine('# --- EMBEDDED CUSTOM INSTALLERS ---')
[void]$sb.AppendLine('$script:EmbeddedCustomScripts = @{')

[void]$sb.AppendLine('  "app/office_install/install.ps1" = {')
[void]$sb.AppendLine('    $OdtDir = "C:\ProgramData\SZC\InstallCache\odt"')
[void]$sb.AppendLine('    New-Item -ItemType Directory -Force -Path $OdtDir | Out-Null')
[void]$sb.AppendLine('    Set-Content -Path (Join-Path $OdtDir "OfficeCustom.xml") -Value $script:Embedded_OfficeCustomXml -Encoding UTF8 -Force')
[void]$sb.AppendLine('    $OfficeXMLSrc = Join-Path $OdtDir "OfficeCustom.xml"')
[void]$sb.AppendLine($officeInstallScript)
[void]$sb.AppendLine('  }')

[void]$sb.AppendLine('  "app/kes_install/install.ps1" = {')
[void]$sb.AppendLine($kesInstallScript)
[void]$sb.AppendLine('  }')

[void]$sb.AppendLine('  "app/bnsc_install/install.ps1" = {')
[void]$sb.AppendLine($bnscInstallScript)
[void]$sb.AppendLine('  }')

[void]$sb.AppendLine('  "app/lockxls_install/install.ps1" = {')
[void]$sb.AppendLine($lockxlsInstallScript)
[void]$sb.AppendLine('  }')

[void]$sb.AppendLine('  "app/autocad_install/install.ps1" = {')
[void]$sb.AppendLine($autocadInstallScript)
[void]$sb.AppendLine('  }')

[void]$sb.AppendLine('  "app/netfx35_install/install.ps1" = {')
[void]$sb.AppendLine($netfx35InstallScript)
[void]$sb.AppendLine('  }')

[void]$sb.AppendLine('}')
[void]$sb.AppendLine("")

# Inlined Install-App function
[void]$sb.AppendLine(@'
function Install-App
{
  [CmdletBinding()]
  param (
    [String]$Name,
    [String]$PackageName,
    [String]$PackageManager,
    [String]$CustomScript,
    [String[]]$InstallArgs
  )

  if ($CustomScript)
  {
    Write-Host "Running custom installer for $Name..." -ForegroundColor Cyan
    $normalizedKey = $CustomScript.Replace('\', '/')
    if ($script:EmbeddedCustomScripts.ContainsKey($normalizedKey))
    {
      & $script:EmbeddedCustomScripts[$normalizedKey]
    }
    elseif (Test-Path $CustomScript)
    {
      $scriptDir = Split-Path $CustomScript -Parent
      Push-Location $scriptDir
      try { . $CustomScript } finally { Pop-Location }
    }
    else
    {
      throw "Custom script not found: $CustomScript"
    }
  }
  else
  {
    $Command = @("install", "-e", "--id", $PackageName,
                 "--accept-package-agreements", "--accept-source-agreements", "-h")
    
    if ($InstallArgs -and $InstallArgs.Count -gt 0)
    {
      $Command += $InstallArgs
    }
    
    Write-Host "Running: $PackageManager $($Command -join ' ')"
    & $PackageManager @Command

    if ($LASTEXITCODE -and $LASTEXITCODE -ne 0)
    {
      throw "'$Name' installer exited with code $LASTEXITCODE."
    }
  }

  Write-Host "Successfully installed: $Name" -ForegroundColor Green
}
'@)
[void]$sb.AppendLine("")

# Embed TUI Components
[void]$sb.AppendLine('# --- TUI COMPONENTS ---')
[void]$sb.AppendLine($tuiUtils)
[void]$sb.AppendLine($tuiApp)
[void]$sb.AppendLine($tuiPrinter)
[void]$sb.AppendLine($tuiInfo)
[void]$sb.AppendLine("")

# Embed TUI Main Coordinator
[void]$sb.AppendLine('# --- TUI COORDINATOR ---')
[void]$sb.AppendLine(@'
$_apps = $script:Embedded_AppsJson | ConvertFrom-Json
$CommonApps = foreach ($app in ($_apps | Where-Object { -not $_.disabled })) {
  $customScript = ""
  if ($app.customScript) {
    $customScript = $app.customScript
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

$_printers = $script:Embedded_PrintersJson | ConvertFrom-Json
$Printers = foreach ($printer in $_printers) {
  $dup = if ($printer.duplex) { $printer.duplex } elseif ($printer.duplexMode) { $printer.duplexMode } else { $null }
  @{
    Id                = $printer.id
    Name              = $printer.name
    Url               = $printer.url
    Port              = $printer.port
    PortType          = $printer.portType
    LprQueue          = $printer.lprQueue
    Driver            = $printer.driver
    DriverUrl         = $printer.driverUrl
    DriverInstallArgs = @($printer.driverInstallArgs)
    IppPath           = $printer.ippPath
    PaperSize         = $printer.paperSize
    Duplex            = $dup
  }
}

$script:Departments = $script:Embedded_DepartmentsJson | ConvertFrom-Json

$script:selectedApps = @{}
$script:selectedPrinters = @{}
$script:currentDepartmentName = ""

function Apply-DepartmentProfile ($dept)
{
  foreach ($app in $CommonApps) { $script:selectedApps[$app.Id] = $false }
  foreach ($printer in $Printers) { $script:selectedPrinters[$printer.Id] = $false }
  foreach ($appId in $dept.apps) { $script:selectedApps[$appId] = $true }
  foreach ($printerId in $dept.printers) { $script:selectedPrinters[$printerId] = $true }
  $script:currentDepartmentName = $dept.name
}

foreach ($app in $CommonApps) { $script:selectedApps[$app.Id] = $false }
foreach ($printer in $Printers) { $script:selectedPrinters[$printer.Id] = $false }
$script:currentDepartmentName = "None"

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
  $printersToInstall = $Printers | Where-Object { $script:selectedPrinters[$_.Id] }

  if ($appsToInstall.Count -eq 0 -and $printersToInstall.Count -eq 0)
  {
    Write-Host "  No applications or printers selected for installation." -ForegroundColor Yellow
    Show-PressEnterToContinue
    return
  }

  $selectedIds = [System.Collections.Generic.HashSet[string]]::new()
  foreach ($app in $appsToInstall) { $selectedIds.Add($app.Id) | Out-Null }

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

  if ($depsAdded.Count -gt 0)
  {
    $depApps = $CommonApps | Where-Object { $depsAdded -contains $_.Id }
    $appsToInstall = @($depApps) + @($appsToInstall)
  }
  else
  {
    $orderedList = [System.Collections.Generic.List[hashtable]]::new()
    $addedIds = [System.Collections.Generic.HashSet[string]]::new()
    foreach ($app in $appsToInstall)
    {
      foreach ($depId in $app.Dependencies)
      {
        if (-not $addedIds.Contains($depId))
        {
          $depApp = $CommonApps | Where-Object { $_.Id -eq $depId } | Select-Object -First 1
          if ($depApp) { $orderedList.Add($depApp); $addedIds.Add($depId) | Out-Null }
        }
      }
      if (-not $addedIds.Contains($app.Id))
      {
        $orderedList.Add($app)
        $addedIds.Add($app.Id) | Out-Null
      }
    }
    $appsToInstall = $orderedList.ToArray()
  }

  Write-Header "CONFIRM DEPLOYMENT"
  Write-Host "  Profile: $($script:currentDepartmentName)" -ForegroundColor Yellow
  Write-Host ""

  if ($appsToInstall.Count -gt 0)
  {
    Write-Host "  Applications to install:" -ForegroundColor Cyan
    foreach ($app in $appsToInstall)
    { Write-Host "    - $($app.Name)" }
  }

  if ($printersToInstall.Count -gt 0)
  {
    Write-Host ""
    Write-Host "  Printers to install:" -ForegroundColor Cyan
    foreach ($p in $printersToInstall)
    { Write-Host "    - $($p.Name) ($($p.Url))" }
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

  $appResults     = [System.Collections.Generic.List[hashtable]]::new()
  $printerResults = [System.Collections.Generic.List[hashtable]]::new()

  Clear-Host
  Write-Header "DEPLOYMENT IN PROGRESS"
  Write-Host ""

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

  if ($printersToInstall.Count -gt 0)
  {
    Write-Host ""
    Write-Host "  [*] Installing printers..." -ForegroundColor Cyan
    Write-Host ""
    foreach ($printer in $printersToInstall)
    {
      Write-Host "  --> $($printer.Name) ($($printer.Url))..." -ForegroundColor Yellow -NoNewline
      $result = @{ Name = $printer.Name; Status = ""; Error = "" }
      try
      {
        Install-LocalPrinter -Name $printer.Name -Url $printer.Url `
          -Port $printer.Port -PortType $printer.PortType `
          -LprQueue $printer.LprQueue -Driver $printer.Driver `
          -DriverUrl $printer.DriverUrl -DriverInstallArgs $printer.DriverInstallArgs `
          -IppPath $printer.IppPath -PaperSize $printer.PaperSize -Duplex $printer.Duplex
        $result.Status = "OK"
        Write-Host " Done" -ForegroundColor Green
      } catch
      {
        $result.Status = "FAILED"
        $result.Error  = $_.Exception.Message
        Write-Host " FAILED" -ForegroundColor Red
        Write-Host "      $($_.Exception.Message)" -ForegroundColor DarkRed
      }
      $printerResults.Add($result)
    }
  }

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

  if ($printerResults.Count -gt 0)
  {
    Write-Host ""
    Write-Host "  PRINTERS" -ForegroundColor Cyan
    Write-Host "  --------"
    foreach ($r in $printerResults)
    {
      if ($r.Status -eq "OK")
      { Write-Host "  [ OK ]  $($r.Name)" -ForegroundColor Green }
      else
      {
        Write-Host "  [FAIL]  $($r.Name)" -ForegroundColor Red
        if ($r.Error) { Write-Host "          $($r.Error)" -ForegroundColor DarkRed }
      }
    }
    $pOk   = ($printerResults | Where-Object { $_.Status -eq "OK" }).Count
    $pFail = $printerResults.Count - $pOk
    Write-Host ""
    Write-Host "  Result: $pOk / $($printerResults.Count) installed." -ForegroundColor $(if ($pFail -eq 0) { "Green" } else { "Yellow" })
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
    
    $appCount = ($script:selectedApps.Values | Where-Object { $_ }).Count
    $printerCount = ($script:selectedPrinters.Values | Where-Object { $_ }).Count
    Write-Host " Selected: $appCount/$($CommonApps.Count) Apps, $printerCount/$($Printers.Count) Printers"
    Write-Footer
    Write-Host "  1. Select User Department Profile"
    Write-Host "  2. Customize Selected Applications"
    Write-Host "  3. Customize Selected Printers"
    Write-Host "  4. Collect User & System Information"
    Write-Host "  5. Start Deployment"
    Write-Host "  6. Exit"
    Write-Footer
    Write-Host ""
    
    $choice = (Read-Host "Choose an option (1-6)").Trim()
    
    switch ($choice)
    {
      "1" { Show-DepartmentMenu }
      "2" { Show-AppSelectionMenu }
      "3" { Show-PrinterSelectionMenu }
      "4" { Get-SystemInformation }
      "5" { Start-Deployment }
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
'@)
[void]$sb.AppendLine("")

# Launch entrypoint
[void]$sb.AppendLine("# --- LAUNCH DEPLOYMENT ---")
[void]$sb.AppendLine("Start-Tui")
[void]$sb.AppendLine('Write-Host ""')
[void]$sb.AppendLine('Write-Host "Session ended. Press Enter to close this window..." -ForegroundColor DarkGray')
[void]$sb.AppendLine('Read-Host | Out-Null')

[System.IO.File]::WriteAllText($outputFile, $sb.ToString(), [System.Text.Encoding]::UTF8)

$sizeKb = [math]::Round((Get-Item $outputFile).Length / 1KB, 2)
Write-Host "Bundled script created successfully!" -ForegroundColor Green
Write-Host "  Path: $outputFile" -ForegroundColor Yellow
Write-Host "  Size: $sizeKb KB" -ForegroundColor Yellow
