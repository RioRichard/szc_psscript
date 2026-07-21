# Use $MyInvocation to find this script's own directory — works correctly even when dot-sourced
$_thisDir     = Split-Path $MyInvocation.MyCommand.Path -Parent
$OfficeXMLSrc = Join-Path $_thisDir "OfficeCustom.xml"

$CacheDir = "C:\ProgramData\SZC\InstallCache"
$OdtDir   = Join-Path $CacheDir "odt"

# Ensure directories exist
New-Item -ItemType Directory -Force -Path $CacheDir | Out-Null
New-Item -ItemType Directory -Force -Path $OdtDir   | Out-Null

# Copy XML to cache dir (space-free path, quoted in ArgumentList for safety)
$OfficeXML = Join-Path $OdtDir "OfficeCustom.xml"
Copy-Item -Path $OfficeXMLSrc -Destination $OfficeXML -Force

# --- Step 1: Download the ODT self-extracting package ---
# This fwlink downloads the real Office Deployment Tool (ODT), NOT the consumer
# OfficeSetup.exe bootstrapper. The ODT must be extracted first to get setup.exe,
# which is the only binary that supports: setup.exe /configure <xml>
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

# --- Step 2: Extract setup.exe from the ODT self-extracting package ---
# The ODT package is a self-extracting exe; /quiet suppresses UI, /extract targets a folder
Write-Output "Extracting ODT setup.exe to: $OdtDir"
$extractProc = Start-Process `
  -FilePath $OdtPkg `
  -ArgumentList @("/quiet", "/extract:`"$OdtDir`"") `
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

# --- Step 3: Run setup.exe /configure with our XML (fully silent) ---
Write-Output "Starting Office 365 deployment with config: $OfficeXML"
$Proc = Start-Process `
  -FilePath $SetupExe `
  -ArgumentList @("/configure", "`"$OfficeXML`"") `
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
  throw "Office setup failed with exit code $exitCode. Check logs in %TEMP% for details."
}
