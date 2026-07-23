$Url      = "https://aes.s.kaspersky-labs.com/endpoints/keswin11/14.0.0.504/vietnamese-INT-21.25.7.504.0.143.0/a0b3932eaa6c05bcb1ae932d500116a2/keswin_14.0.0.504_vi_aes56.exe"
$CacheDir = "C:\ProgramData\SZC\InstallCache"
$KesDir   = Join-Path $CacheDir "kes_extracted"

# Ensure directories exist
New-Item -ItemType Directory -Force -Path $CacheDir | Out-Null
New-Item -ItemType Directory -Force -Path $KesDir   | Out-Null

$DownloadedExe = Join-Path $CacheDir "keswin_setup.exe"
$ArchiveAs7z   = Join-Path $CacheDir "keswin_setup.7z"

# --- Step 1: Ensure download helper is loaded and download installer ---
if (-not (Get-Command Start-MultiDownload -ErrorAction SilentlyContinue))
{
  $_thisDir = Split-Path $MyInvocation.MyCommand.Path -Parent
  $_helperPath = Join-Path $_thisDir "..\download_helper.ps1"
  if (Test-Path $_helperPath)
  { . $_helperPath 
  }
}

# Remove leftover download if present
if (Test-Path $DownloadedExe)
{ Remove-Item $DownloadedExe -Force -ErrorAction SilentlyContinue 
}

Write-Host "Downloading Kaspersky Endpoint Security..."
Start-MultiDownload -Url $Url -OutFile $DownloadedExe -Connections 8 -ActivityName "Downloading Kaspersky Endpoint Security"

if (-not (Test-Path $DownloadedExe))
{
  throw "Kaspersky installer file missing after download."
}

# --- Step 2: Rename .exe -> .7z so 7-Zip can extract it ---
Copy-Item -Path $DownloadedExe -Destination $ArchiveAs7z -Force

# --- Step 3: Locate 7-Zip executable ---
$7zPaths = @(
  "C:\Program Files\7-Zip\7z.exe",
  "C:\Program Files (x86)\7-Zip\7z.exe"
)
$7zExe = $7zPaths | Where-Object { Test-Path $_ } | Select-Object -First 1

if (-not $7zExe)
{
  throw "7-Zip is not installed. Please install 7-Zip before deploying Kaspersky Endpoint Security."
}

# --- Step 4: Extract the archive ---
Write-Host "Extracting KES package with 7-Zip..."
$extractProc = Start-Process `
  -FilePath $7zExe `
  -ArgumentList @("x", "`"$ArchiveAs7z`"", "-o`"$KesDir`"", "-y") `
  -NoNewWindow `
  -PassThru `
  -Wait

if ($extractProc.ExitCode -ne 0)
{
  throw "7-Zip extraction failed with exit code $($extractProc.ExitCode)."
}

# --- Step 5: Find installer inside the extracted folder (prioritize MSI) ---
$realInstaller = Get-ChildItem -Path $KesDir -Filter "*.msi" -Recurse -ErrorAction SilentlyContinue |
  Select-Object -First 1

if (-not $realInstaller)
{
  # Fallback 1: setup.exe executable
  $realInstaller = Get-ChildItem -Path $KesDir -Filter "*setup*.exe" -Recurse -ErrorAction SilentlyContinue |
    Select-Object -First 1
}

if (-not $realInstaller)
{
  # Fallback 2: any .exe in extracted folder
  $realInstaller = Get-ChildItem -Path $KesDir -Filter "*.exe" -Recurse -ErrorAction SilentlyContinue |
    Select-Object -First 1
}

if (-not $realInstaller)
{
  throw "Could not find a setup executable or MSI package inside the extracted KES package at: $KesDir"
}

Write-Host "Found installer: $($realInstaller.FullName)"

# --- Step 6: Run installer ---
if ($realInstaller.Extension -eq ".msi")
{
  Write-Host "Running Kaspersky MSI installation (unattended, progress bar only)..."
  $installProc = Start-Process `
    -FilePath "msiexec.exe" `
    -ArgumentList @("/i", "`"$($realInstaller.FullName)`"", "/passive", "EULA=1", "PRIVACYPOLICY=1", "KSN=0") `
    -NoNewWindow `
    -PassThru `
    -Wait
} else
{
  Write-Host "Running Kaspersky EXE installation (unattended, progress bar parameters)..."
  $installProc = Start-Process `
    -FilePath $realInstaller.FullName `
    -ArgumentList @("/s", "/pEULA=1", "/pPRIVACYPOLICY=1", "/pKSN=0", "/v`"/passive EULA=1 PRIVACYPOLICY=1 KSN=0`"") `
    -NoNewWindow `
    -PassThru `
    -Wait
}

$exitCode = $installProc.ExitCode
Write-Host "KES installer exited with code: $exitCode"

# --- Step 7: Cleanup (only on success) ---
if ($exitCode -eq 0)
{
  Remove-Item $DownloadedExe -Force -ErrorAction SilentlyContinue
  Remove-Item $ArchiveAs7z   -Force -ErrorAction SilentlyContinue
  Remove-Item $KesDir        -Recurse -Force -ErrorAction SilentlyContinue
  Write-Host "Kaspersky Endpoint Security installed successfully."
} else
{
  Write-Host "Files left in: $CacheDir and $KesDir (for retry/debugging)"
  throw "KES installation failed with exit code $exitCode."
}
