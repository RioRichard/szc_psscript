# Du toan BNSC Installer
# Downloads from Google Drive and installs silently.
# Dependencies: .NET Framework 3.5, VS Tools for Office 2010, Microsoft Office
#
# TODO: Replace $DownloadUrl with the actual Google Drive direct download link.
# Google Drive direct download format:
#   https://drive.google.com/uc?export=download&id=FILE_ID
# Or for large files:
#   https://drive.usercontent.google.com/download?id=FILE_ID&confirm=xxx

$CacheDir    = "C:\ProgramData\SZC\InstallCache\bnsc"
$DownloadUrl = "https://drive.google.com/file/d/15PJp17mN5XNhYf-H8yDoBeFUURu2VMmG/view?pli=1"
$InstallerName = "Cai_dat_du_toan_BNSC.exe"
$InstallerPath = Join-Path $CacheDir $InstallerName

if ([string]::IsNullOrWhiteSpace($DownloadUrl)) {
    throw "BNSC download URL is not configured. Update the `$DownloadUrl variable in bnsc_install/install.ps1"
}

# Create cache directory
if (-not (Test-Path $CacheDir)) {
    New-Item -ItemType Directory -Path $CacheDir -Force | Out-Null
}

# Download installer if not cached
if (-not (Test-Path $InstallerPath)) {
    Write-Host "Downloading BNSC installer from Google Drive..."
    # Dot-source download helper
    $dlHelper = Join-Path $PSScriptRoot "..\download_helper.ps1"
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
# NOTE: BNSC installer may require antivirus to be temporarily disabled.
# The installer is typically a GUI wizard. Running without /S for now.
Write-Host "Running BNSC installer..."
Write-Host "  NOTE: If antivirus blocks the install, temporarily disable it." -ForegroundColor Yellow

$process = Start-Process -FilePath $InstallerPath -NoNewWindow -PassThru -Wait

if ($process.ExitCode -ne 0) {
    throw "BNSC installation failed with exit code: $($process.ExitCode)"
}

Write-Host "BNSC installed successfully."
Write-Host "  Remember to plug in the USB dongle for license activation." -ForegroundColor Yellow
