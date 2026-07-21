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

# Remove any leftover partial/corrupt download from a previous attempt
if (Test-Path $OdtPkg) { Remove-Item $OdtPkg -Force }

# --- Download helper function with two methods ---
# Method 1: Invoke-WebRequest (with ProgressPreference disabled and explicit redirect following)
# Method 2: System.Net.WebClient (more reliable for binary downloads through redirects)
function Download-OdtPackage
{
  param([string]$Url, [string]$OutFile)

  # --- Try Method 1: Invoke-WebRequest ---
  Write-Output "Downloading ODT (Method 1: Invoke-WebRequest)..."
  try
  {
    # Disable progress bar — it is known to stall or corrupt downloads in PowerShell
    $oldProgress = $ProgressPreference
    $ProgressPreference = 'SilentlyContinue'
    try
    {
      Invoke-WebRequest -Uri $Url -OutFile $OutFile -UseBasicParsing -MaximumRedirection 10
    }
    finally
    {
      $ProgressPreference = $oldProgress
    }

    # Quick sanity check — if file exists and is > 100KB, Method 1 likely succeeded
    if ((Test-Path $OutFile) -and ((Get-Item $OutFile).Length -gt 100KB))
    {
      return
    }
    Write-Output "Method 1 produced a small or missing file, falling back..."
  }
  catch
  {
    Write-Output "Method 1 failed: $($_.Exception.Message). Falling back..."
  }

  # Clean up before retry
  if (Test-Path $OutFile) { Remove-Item $OutFile -Force }

  # --- Try Method 2: System.Net.WebClient ---
  # WebClient handles fwlink redirects more reliably than Invoke-WebRequest
  Write-Output "Downloading ODT (Method 2: System.Net.WebClient)..."
  try
  {
    $wc = New-Object System.Net.WebClient
    $wc.DownloadFile($Url, $OutFile)
  }
  catch
  {
    throw "Both download methods failed. Last error: $($_.Exception.Message)"
  }
  finally
  {
    if ($wc) { $wc.Dispose() }
  }
}

Download-OdtPackage -Url $OdtUrl -OutFile $OdtPkg

# --- Verify the download is a real binary, not an HTML error/redirect page ---
if (-not (Test-Path $OdtPkg))
{
  throw "ODT package file not found after download."
}

$odtSize = (Get-Item $OdtPkg).Length
Write-Output "ODT package downloaded: $odtSize bytes"

# The real ODT package is ~3.4 MB. Anything under 500KB is almost certainly an HTML
# redirect page, an error page, or a truncated download.
if ($odtSize -lt 500KB)
{
  # Check if the file looks like HTML (redirect page) rather than a binary
  $head = Get-Content $OdtPkg -TotalCount 5 -ErrorAction SilentlyContinue
  $headText = ($head -join "`n").ToLower()
  if ($headText -match '<html|<head|<!doctype|window\.location')
  {
    Remove-Item $OdtPkg -Force -ErrorAction SilentlyContinue
    throw "ODT download returned an HTML page instead of a binary (redirect not followed). " +
          "Check network/proxy settings. File was $odtSize bytes."
  }
  Remove-Item $OdtPkg -Force -ErrorAction SilentlyContinue
  throw "ODT package too small ($odtSize bytes) — download may be truncated or corrupted. " +
        "Expected ~3.4 MB. Check network connectivity."
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
