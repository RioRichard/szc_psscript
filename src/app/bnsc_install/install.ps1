# Du toan BNSC Installer
# Downloads from Google Drive and installs silently.
# Dependencies: .NET Framework 3.5, VS Tools for Office 2010, Microsoft Office

$CacheDir    = "C:\ProgramData\SZC\InstallCache\bnsc"
$DownloadUrl = "https://drive.google.com/file/d/15PJp17mN5XNhYf-H8yDoBeFUURu2VMmG/view?pli=1"
$InstallerName = "Cai_dat_du_toan_BNSC.exe"
$InstallerPath = Join-Path $CacheDir $InstallerName

if ([string]::IsNullOrWhiteSpace($DownloadUrl)) {
    throw "BNSC download URL is not configured. Update the `$DownloadUrl variable in bnsc_install/install.ps1"
}

# --- Helper functions to temporarily bypass Antivirus (Defender / KES) ---
function Disable-AntivirusProtection {
    Write-Host "Temporarily adjusting Antivirus settings for BNSC installation..." -ForegroundColor Yellow

    # 1. Windows Defender Exclusions & Real-time pause
    try {
        if (Get-Command "Add-MpPreference" -ErrorAction SilentlyContinue) {
            Add-MpPreference -ExclusionPath $CacheDir -ErrorAction SilentlyContinue
            Add-MpPreference -ExclusionPath "C:\Program Files (x86)\BNSC" -ErrorAction SilentlyContinue
            Add-MpPreference -ExclusionPath "C:\Program Files\BNSC" -ErrorAction SilentlyContinue
            Add-MpPreference -ExclusionPath "C:\ProgramData\SZC" -ErrorAction SilentlyContinue
            Add-MpPreference -ExclusionPath "C:\SecureDongle.dll" -ErrorAction SilentlyContinue
            Add-MpPreference -ExclusionProcess $InstallerName -ErrorAction SilentlyContinue
            Set-MpPreference -DisableRealtimeMonitoring $true -ErrorAction SilentlyContinue
            Write-Host "  Windows Defender real-time monitoring paused & BNSC exclusions added." -ForegroundColor Green
        }
    } catch {
        Write-Host "  (Notice: Windows Defender preference modification skipped)" -ForegroundColor DarkGray
    }

    # 2. Kaspersky Endpoint Security (KES) - Pause via avp.com CLI if installed
    $kesPaths = @(
        "$env:ProgramFiles (x86)\Kaspersky Lab\Kaspersky Endpoint Security for Windows\avp.com",
        "$env:ProgramFiles\Kaspersky Lab\Kaspersky Endpoint Security for Windows\avp.com"
    )
    foreach ($avp in $kesPaths) {
        if (Test-Path $avp) {
            try {
                Write-Host "  Found Kaspersky Endpoint Security, pausing protection..." -ForegroundColor Yellow
                Start-Process -FilePath $avp -ArgumentList "STOP" -NoNewWindow -Wait -ErrorAction SilentlyContinue
            } catch {
                Write-Host "  (Notice: Could not pause Kaspersky automatically)" -ForegroundColor DarkGray
            }
        }
    }
}

function Restore-AntivirusProtection {
    Write-Host "Restoring Antivirus settings..." -ForegroundColor Yellow

    # Re-enable Windows Defender real-time monitoring
    try {
        if (Get-Command "Set-MpPreference" -ErrorAction SilentlyContinue) {
            Set-MpPreference -DisableRealtimeMonitoring $false -ErrorAction SilentlyContinue
            Write-Host "  Windows Defender real-time monitoring restored." -ForegroundColor Green
        }
    } catch {}

    # Resume Kaspersky Endpoint Security
    $kesPaths = @(
        "$env:ProgramFiles (x86)\Kaspersky Lab\Kaspersky Endpoint Security for Windows\avp.com",
        "$env:ProgramFiles\Kaspersky Lab\Kaspersky Endpoint Security for Windows\avp.com"
    )
    foreach ($avp in $kesPaths) {
        if (Test-Path $avp) {
            try {
                Start-Process -FilePath $avp -ArgumentList "START" -NoNewWindow -Wait -ErrorAction SilentlyContinue
                Write-Host "  Kaspersky protection resumed." -ForegroundColor Green
            } catch {}
        }
    }
}

# --- Create C:\SecureDongle.dll Symlink for Standard Non-Admin User Access ---
function Setup-SecureDongleFileSymlink {
    $targetFile = "C:\ProgramData\SZC\SecureDongle.dll"
    $linkPath   = "C:\SecureDongle.dll"

    Write-Host "Setting up C:\SecureDongle.dll file symlink for non-admin user access..." -ForegroundColor Cyan

    $szcDir = Split-Path $targetFile -Parent
    if (-not (Test-Path $szcDir)) {
        New-Item -ItemType Directory -Path $szcDir -Force | Out-Null
    }

    # Ensure target file exists in ProgramData
    if (-not (Test-Path $targetFile)) {
        New-Item -ItemType File -Path $targetFile -Force | Out-Null
    }

    # Grant FullControl permissions to local users on target file
    try {
        $acl = Get-Acl $targetFile
        $rule = New-Object System.Security.AccessControl.FileSystemAccessRule(
            "Users", "FullControl", "Allow"
        )
        $acl.AddAccessRule($rule)
        Set-Acl -Path $targetFile -AclObject $acl
        Write-Host "  Granted Full Control permissions on $targetFile to local users." -ForegroundColor Green
    } catch {
        Write-Host "  (Notice: Could not update ACL permissions on $targetFile)" -ForegroundColor DarkGray
    }

    # Create Symbolic Link at C:\SecureDongle.dll if not present
    if (-not (Test-Path $linkPath)) {
        try {
            New-Item -ItemType SymbolicLink -Path $linkPath -Target $targetFile -Force | Out-Null
            Write-Host "  Created File Symlink: $linkPath -> $targetFile" -ForegroundColor Green
        } catch {
            Write-Host "  Fallback creating file symlink via cmd..." -ForegroundColor Yellow
            cmd /c "mklink `"$linkPath`" `"$targetFile`"" | Out-Null
        }

        # Also grant FullControl on the link path itself
        try {
            if (Test-Path $linkPath) {
                $linkAcl = Get-Acl $linkPath
                $rule = New-Object System.Security.AccessControl.FileSystemAccessRule("Users", "FullControl", "Allow")
                $linkAcl.AddAccessRule($rule)
                Set-Acl -Path $linkPath -AclObject $linkAcl
            }
        } catch {}
    } else {
        Write-Host "  Path $linkPath already exists. Updating ACL permissions..." -ForegroundColor DarkGray
        try {
            $linkAcl = Get-Acl $linkPath
            $rule = New-Object System.Security.AccessControl.FileSystemAccessRule("Users", "FullControl", "Allow")
            $linkAcl.AddAccessRule($rule)
            Set-Acl -Path $linkPath -AclObject $linkAcl
            Write-Host "  Granted Full Control permissions on $linkPath to local users." -ForegroundColor Green
        } catch {}
    }
}

# --- Main Installation Logic ---

Disable-AntivirusProtection

try {
    # Set up SecureDongle.dll file symlink & permissions before installing
    Setup-SecureDongleFileSymlink

    # Create cache directory
    if (-not (Test-Path $CacheDir)) {
        New-Item -ItemType Directory -Path $CacheDir -Force | Out-Null
    }

    # Download installer if not cached
    if (-not (Test-Path $InstallerPath)) {
        Write-Host "Downloading BNSC installer from Google Drive..."
        $dlHelper = Join-Path (Split-Path $MyInvocation.MyCommand.Path -Parent) "..\download_helper.ps1"
        if (Test-Path $dlHelper) { . $dlHelper }

        if (Get-Command "Start-GoogleDriveDownload" -ErrorAction SilentlyContinue) {
            Start-GoogleDriveDownload -UrlOrId $DownloadUrl -OutFile $InstallerPath
        } else {
            throw "Download helper function Start-GoogleDriveDownload not found."
        }
    } else {
        Write-Host "Using cached BNSC installer: $InstallerPath"
    }

    # Run installer
    Write-Host "Running BNSC installer..."
    $process = Start-Process -FilePath $InstallerPath -NoNewWindow -PassThru -Wait

    if ($process.ExitCode -ne 0) {
        throw "BNSC installation failed with exit code: $($process.ExitCode)"
    }

    Write-Host "BNSC installed successfully." -ForegroundColor Green
    Write-Host "  Remember to plug in the USB dongle for license activation." -ForegroundColor Yellow
}
finally {
    Restore-AntivirusProtection
}
