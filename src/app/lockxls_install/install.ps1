# LockXLS Installer
# Must be installed AFTER BNSC to ensure BNSC works correctly.
# Dependency chain: .NET 3.5 -> VSTOR -> Office -> BNSC -> LockXLS

$CacheDir     = "C:\ProgramData\SZC\InstallCache\lockxls"
$DownloadUrl  = "https://drive.google.com/file/d/1KdQyb6YEsB3LtDEK9cHNUfWdoULKobke/view?usp=drive_link"
$ZipName      = "lockxls_setup.zip"
$ZipPath      = Join-Path $CacheDir $ZipName
$ExtractDir   = Join-Path $CacheDir "extracted"

if ([string]::IsNullOrWhiteSpace($DownloadUrl)) {
    throw "LockXLS download URL is not configured. Update the `$DownloadUrl variable in lockxls_install/install.ps1"
}

# --- Helper functions to temporarily bypass Antivirus (Defender / KES) ---
function Disable-AntivirusProtection {
    Write-Host "Temporarily adjusting Antivirus settings for LockXLS installation..." -ForegroundColor Yellow
    try {
        if (Get-Command "Add-MpPreference" -ErrorAction SilentlyContinue) {
            Add-MpPreference -ExclusionPath $CacheDir -ErrorAction SilentlyContinue
            Add-MpPreference -ExclusionPath "C:\Program Files\LockXLS" -ErrorAction SilentlyContinue
            Add-MpPreference -ExclusionPath "C:\Program Files (x86)\LockXLS" -ErrorAction SilentlyContinue
            Set-MpPreference -DisableRealtimeMonitoring $true -ErrorAction SilentlyContinue
        }
    } catch {}

    $kesPaths = @(
        "$env:ProgramFiles (x86)\Kaspersky Lab\Kaspersky Endpoint Security for Windows\avp.com",
        "$env:ProgramFiles\Kaspersky Lab\Kaspersky Endpoint Security for Windows\avp.com"
    )
    foreach ($avp in $kesPaths) {
        if (Test-Path $avp) {
            try {
                Start-Process -FilePath $avp -ArgumentList "STOP" -NoNewWindow -Wait -ErrorAction SilentlyContinue
            } catch {}
        }
    }
}

function Restore-AntivirusProtection {
    try {
        if (Get-Command "Set-MpPreference" -ErrorAction SilentlyContinue) {
            Set-MpPreference -DisableRealtimeMonitoring $false -ErrorAction SilentlyContinue
        }
    } catch {}

    $kesPaths = @(
        "$env:ProgramFiles (x86)\Kaspersky Lab\Kaspersky Endpoint Security for Windows\avp.com",
        "$env:ProgramFiles\Kaspersky Lab\Kaspersky Endpoint Security for Windows\avp.com"
    )
    foreach ($avp in $kesPaths) {
        if (Test-Path $avp) {
            try {
                Start-Process -FilePath $avp -ArgumentList "START" -NoNewWindow -Wait -ErrorAction SilentlyContinue
            } catch {}
        }
    }
}

Disable-AntivirusProtection

try {
    # Create cache directory
    if (-not (Test-Path $CacheDir)) {
        New-Item -ItemType Directory -Path $CacheDir -Force | Out-Null
    }

    # Download installer package if not cached
    if (-not (Test-Path $ZipPath)) {
        Write-Host "Downloading LockXLS package from Google Drive..."
        $dlHelper = Join-Path $PSScriptRoot "..\download_helper.ps1"
        if (Test-Path $dlHelper) { . $dlHelper }

        Start-GoogleDriveDownload -UrlOrId $DownloadUrl -OutFile $ZipPath
    } else {
        Write-Host "Using cached LockXLS package: $ZipPath"
    }

    # Extract package
    Write-Host "Extracting LockXLS installer..."
    if (Test-Path $ExtractDir) {
        Remove-Item -Path $ExtractDir -Recurse -Force -ErrorAction SilentlyContinue
    }
    New-Item -ItemType Directory -Path $ExtractDir -Force | Out-Null

    try {
        Expand-Archive -Path $ZipPath -DestinationPath $ExtractDir -Force -ErrorAction Stop
    } catch {
        # Fallback to 7-Zip CLI if available
        $7zExe = Join-Path $env:ProgramFiles "7-Zip\7z.exe"
        if (Test-Path $7zExe) {
            & $7zExe x "$ZipPath" "-o$ExtractDir" -y | Out-Null
        } else {
            throw "Failed to extract LockXLS zip archive: $($_.Exception.Message)"
        }
    }

    # Find .msi inside extracted folder
    $msiFile = Get-ChildItem -Path $ExtractDir -Filter "*.msi" -Recurse | Select-Object -First 1
    if (-not $msiFile) {
        throw "No .msi installer found inside LockXLS package."
    }

    # Run MSI installer silently
    Write-Host "Executing silent LockXLS installation ($($msiFile.Name))..."
    $process = Start-Process -FilePath "msiexec.exe" `
        -ArgumentList "/i `"$($msiFile.FullName)`" /passive /norestart" `
        -NoNewWindow -PassThru -Wait

    if ($process.ExitCode -ne 0) {
        throw "LockXLS installation failed with exit code: $($process.ExitCode)"
    }

    Write-Host "LockXLS installed successfully." -ForegroundColor Green
}
finally {
    Restore-AntivirusProtection
}
