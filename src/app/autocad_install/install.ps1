# AutoCAD LT Custom Installer
# AutoCAD LT uses Named User licensing (sign-in based).
# The deployment package must be created once from the Autodesk Account portal
# and pre-staged to one of the search paths below.
# After installation, the end user signs in with their Autodesk account.

$CacheDir     = "C:\ProgramData\SZC\InstallCache\autocad"
$SetupExeName = "Setup.exe"

# --- Search for Setup.exe across multiple locations ---
Write-Host "Searching for AutoCAD LT installation package..."

# Build list of search paths: local cache first, then USB/removable drives
$searchPaths = @($CacheDir)

# Add all removable and fixed non-system drives (USB sticks, external drives)
try {
    $extraDrives = Get-CimInstance -ClassName Win32_LogicalDisk |
        Where-Object {
            $_.DriveType -in @(2, 3) -and   # 2=Removable, 3=Local Fixed
            $_.DeviceID -ne $env:SystemDrive  # Skip C: (system drive)
        } |
        ForEach-Object { $_.DeviceID }

    foreach ($drive in $extraDrives) {
        # Check root and common subfolder names
        $searchPaths += "$drive\"
        $searchPaths += "$drive\autocad"
        $searchPaths += "$drive\AutoCAD"
        $searchPaths += "$drive\AutoCAD LT"
        $searchPaths += "$drive\SZC\autocad"
        $searchPaths += "$drive\InstallCache\autocad"
    }
} catch {
    Write-Host "  (Could not enumerate extra drives: $($_.Exception.Message))" -ForegroundColor DarkGray
}

$foundSetup = $null
foreach ($searchPath in $searchPaths) {
    $candidate = Join-Path $searchPath $SetupExeName
    if (Test-Path $candidate) {
        $foundSetup = $candidate
        Write-Host "  Found: $candidate" -ForegroundColor Green
        break
    }
}

if (-not $foundSetup) {
    Write-Host ""
    Write-Host "  =============================================" -ForegroundColor Yellow
    Write-Host "  AutoCAD LT setup package NOT FOUND" -ForegroundColor Yellow
    Write-Host "  =============================================" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "  AutoCAD LT cannot be downloaded automatically." -ForegroundColor White
    Write-Host "  A deployment package must be prepared once" -ForegroundColor White
    Write-Host "  from the Autodesk admin portal." -ForegroundColor White
    Write-Host ""
    Write-Host "  How to prepare (one-time):" -ForegroundColor Cyan
    Write-Host "    1. Go to https://manage.autodesk.com" -ForegroundColor White
    Write-Host "    2. Sign in with your admin account" -ForegroundColor White
    Write-Host "    3. Go to Products > AutoCAD LT > Custom Install" -ForegroundColor White
    Write-Host "    4. Configure language and options" -ForegroundColor White
    Write-Host "    5. Download the deployment package" -ForegroundColor White
    Write-Host "    6. Copy the extracted folder (with Setup.exe)" -ForegroundColor White
    Write-Host "       to one of these locations:" -ForegroundColor White
    Write-Host "       - $CacheDir" -ForegroundColor Gray
    Write-Host "       - USB drive root or \autocad subfolder" -ForegroundColor Gray
    Write-Host ""
    Write-Host "  After install, the user signs in with their" -ForegroundColor DarkGray
    Write-Host "  Autodesk account to activate the license." -ForegroundColor DarkGray
    Write-Host ""
    Write-Host "  Searched locations:" -ForegroundColor DarkGray
    foreach ($p in $searchPaths) {
        $status = if (Test-Path $p) { "[exists, no Setup.exe]" } else { "[not found]" }
        Write-Host "    $p $status" -ForegroundColor DarkGray
    }
    Write-Host ""

    # Offer to open the Autodesk portal
    try {
        $openPortal = Read-Host "  Open Autodesk portal in browser? (Y/N)"
        if ($openPortal -eq "Y" -or $openPortal -eq "y") {
            Start-Process "https://manage.autodesk.com/products"
            Write-Host "  Opened browser. Re-run deployment after preparing the package." -ForegroundColor Green
        }
    } catch {
        # Non-critical, ignore
    }

    Write-Host ""
    Write-Host "  Skipping AutoCAD LT installation." -ForegroundColor Yellow
    return
}

# --- Run the installer ---
Write-Host "Using AutoCAD LT setup package at: $foundSetup" -ForegroundColor Cyan

# If found on USB/external drive, copy to local cache first for reliability
$setupDir = Split-Path $foundSetup -Parent
if ($setupDir -ne $CacheDir) {
    Write-Host "  Copying deployment files to local cache: $CacheDir ..."
    if (-not (Test-Path $CacheDir)) {
        New-Item -ItemType Directory -Path $CacheDir -Force | Out-Null
    }
    Copy-Item -Path "$setupDir\*" -Destination $CacheDir -Recurse -Force
    $foundSetup = Join-Path $CacheDir $SetupExeName
    Write-Host "  Copy complete." -ForegroundColor Green
}

Write-Host "Executing silent AutoCAD LT installation..."
Write-Host "  (User will sign in with Autodesk account after install)" -ForegroundColor DarkGray
$process = Start-Process -FilePath $foundSetup -ArgumentList "-q" -NoNewWindow -PassThru -Wait

if ($process.ExitCode -ne 0) {
    throw "AutoCAD LT installation failed with exit code: $($process.ExitCode)"
}

Write-Host "AutoCAD LT installed successfully."
Write-Host "  Remind the user to sign in with their Autodesk account to activate." -ForegroundColor Yellow
