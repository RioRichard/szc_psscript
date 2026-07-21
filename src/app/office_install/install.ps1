# Use $MyInvocation to find this script's own directory — works correctly even when dot-sourced
# ($PSScriptRoot resolves to the CALLER's directory when dot-sourced, so never use it here)
$_thisDir     = Split-Path $MyInvocation.MyCommand.Path -Parent
$OfficeXMLSrc = Join-Path $_thisDir "OfficeCustom.xml"

$CacheDir = "C:\ProgramData\SZC\InstallCache"
$OdtDir   = Join-Path $CacheDir "odt"

# Ensure directories exist
New-Item -ItemType Directory -Force -Path $CacheDir | Out-Null
New-Item -ItemType Directory -Force -Path $OdtDir   | Out-Null

# Copy XML into $OdtDir so setup.exe and OfficeCustom.xml are in the same folder.
# Running setup.exe from the same directory as the XML (with just the filename, no path)
# is the most reliable way to avoid error 0-2048 "couldn't find configuration file".
$OfficeXML = Join-Path $OdtDir "OfficeCustom.xml"
Copy-Item -Path $OfficeXMLSrc -Destination $OfficeXML -Force

# --- Step 1: Download the ODT self-extracting package ---
# LinkID=626065 -> real Office Deployment Tool (officedeploymenttool_*.exe)
# Do NOT use linkid=2264705 — that is the consumer OfficeSetup.exe bootstrapper
# which ignores /configure <xml> entirely and gives a misleading success exit code.
$OdtPkg = Join-Path $CacheDir "officedeploymenttool.exe"
$OdtUrl = "https://go.microsoft.com/fwlink/p/?LinkID=626065"

Write-Output "Downloading Office Deployment Tool (ODT)..."
try
{
  Invoke-WebRequest -Uri $OdtUrl -OutFile $OdtPkg -UseBasicParsing
} catch
{
  throw "Failed to download ODT package: $($_.Exception.Message)"
}

# Verify the download looks like a real binary (not an HTML error page)
$odtSize = (Get-Item $OdtPkg).Length
Write-Output "ODT package downloaded: $odtSize bytes"
if ($odtSize -lt 1MB)
{
  throw "ODT package too small ($odtSize bytes) — download may have failed or returned an error page."
}

# --- Step 2: Extract setup.exe from the ODT self-extracting package ---
# Pass the argument as a single string without quotes around the path.
# Some self-extractors misparse /switch:"quoted path" when the path has no spaces.
Write-Output "Extracting ODT setup.exe to: $OdtDir"
$extractProc = Start-Process `
  -FilePath $OdtPkg `
  -ArgumentList "/quiet /extract:$OdtDir" `
  -NoNewWindow `
  -PassThru `
  -Wait

if ($extractProc.ExitCode -ne 0)
{
  throw "ODT extraction failed with exit code $($extractProc.ExitCode)."
}

$SetupExe = Join-Path $OdtDir "setup.exe"
if (-not (Test-Path $SetupExe))
{
  throw "setup.exe not found after ODT extraction. Expected at: $SetupExe"
}

# --- Step 3: Run setup.exe /configure (fully silent, no UI) ---
# IMPORTANT: Use -WorkingDirectory $OdtDir and pass just the bare filename "OfficeCustom.xml".
# This is the most reliable fix for error 0-2048 — setup.exe looks for the XML
# relative to its working directory, so no path/quoting ambiguity is possible.
Write-Output "Starting Office 365 deployment..."
$Proc = Start-Process `
  -FilePath $SetupExe `
  -ArgumentList "/configure OfficeCustom.xml" `
  -WorkingDirectory $OdtDir `
  -NoNewWindow `
  -PassThru `
  -Wait

$exitCode = $Proc.ExitCode
Write-Output "Office setup exited with code: $exitCode"

# --- Step 4: Cleanup on success ---
if ($exitCode -eq 0)
{
  Remove-Item $OdtPkg -Force -ErrorAction SilentlyContinue
  Write-Output "Office 365 installed successfully."
} else
{
  Write-Output "ODT files left at: $OdtDir (for retry/debugging)"
  throw "Office setup failed with exit code $exitCode. Check ODT logs in %TEMP% for details."
}
