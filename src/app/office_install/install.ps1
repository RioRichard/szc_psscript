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

# --- Step 1: Obtain ODT setup.exe ---
# The fwlink URL (LinkID=626065) redirects to the Microsoft Download Center *web page*,
# NOT a direct binary. Both Invoke-WebRequest and WebClient end up downloading the
# HTML page instead of the real file. This is the root cause of the "small file" errors.
#
# Solution: Download setup.exe directly from the Office CDN, which is a stable, direct
# binary URL that does not involve any redirects or HTML pages.
# This is the same setup.exe that the ODT self-extracting package would have extracted.
$SetupExe = Join-Path $OdtDir "setup.exe"
$CdnUrl   = "https://officecdn.microsoft.com/pr/wsus/setup.exe"

# Remove any leftover partial/corrupt download from a previous attempt
if (Test-Path $SetupExe) { Remove-Item $SetupExe -Force }

# --- Download helper: try multiple methods for maximum reliability ---
function Download-SetupExe
{
  param([string]$Url, [string]$OutFile)

  # --- Method 1: curl.exe (ships with Windows 10 1803+ / Windows 11) ---
  # curl.exe handles redirects natively with -L and is the most reliable option.
  $curlPath = Get-Command curl.exe -ErrorAction SilentlyContinue
  if ($curlPath)
  {
    Write-Output "Downloading setup.exe (Method 1: curl.exe)..."
    try
    {
      $curlProc = Start-Process -FilePath "curl.exe" `
        -ArgumentList "-L", "-o", "`"$OutFile`"", "--retry", "3", "--retry-delay", "5", "-s", "-S", "`"$Url`"" `
        -NoNewWindow -PassThru -Wait

      if ($curlProc.ExitCode -eq 0 -and (Test-Path $OutFile) -and ((Get-Item $OutFile).Length -gt 100KB))
      {
        return
      }
      Write-Output "curl.exe produced a small or missing file (exit code $($curlProc.ExitCode)), falling back..."
    }
    catch
    {
      Write-Output "curl.exe failed: $($_.Exception.Message). Falling back..."
    }
    if (Test-Path $OutFile) { Remove-Item $OutFile -Force }
  }

  # --- Method 2: Invoke-WebRequest (with ProgressPreference disabled) ---
  Write-Output "Downloading setup.exe (Method 2: Invoke-WebRequest)..."
  try
  {
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

    if ((Test-Path $OutFile) -and ((Get-Item $OutFile).Length -gt 100KB))
    {
      return
    }
    Write-Output "Invoke-WebRequest produced a small or missing file, falling back..."
  }
  catch
  {
    Write-Output "Invoke-WebRequest failed: $($_.Exception.Message). Falling back..."
  }
  if (Test-Path $OutFile) { Remove-Item $OutFile -Force }

  # --- Method 3: System.Net.WebClient ---
  Write-Output "Downloading setup.exe (Method 3: System.Net.WebClient)..."
  try
  {
    $wc = New-Object System.Net.WebClient
    $wc.DownloadFile($Url, $OutFile)
  }
  catch
  {
    throw "All download methods failed. Last error: $($_.Exception.Message)"
  }
  finally
  {
    if ($wc) { $wc.Dispose() }
  }
}

Download-SetupExe -Url $CdnUrl -OutFile $SetupExe

# --- Validate the downloaded setup.exe ---
if (-not (Test-Path $SetupExe))
{
  throw "setup.exe not found after download."
}

$setupSize = (Get-Item $SetupExe).Length
Write-Output "setup.exe downloaded: $setupSize bytes"

# The real setup.exe is typically > 7 MB. Anything under 500KB is suspicious.
if ($setupSize -lt 500KB)
{
  # Check if the file looks like HTML (redirect page) rather than a binary
  $head = Get-Content $SetupExe -TotalCount 5 -ErrorAction SilentlyContinue
  $headText = ($head -join "`n").ToLower()
  if ($headText -match '<html|<head|<!doctype|window\.location')
  {
    Remove-Item $SetupExe -Force -ErrorAction SilentlyContinue
    throw "Download returned an HTML page instead of setup.exe. " +
          "Check network/proxy settings. File was $setupSize bytes."
  }
  Remove-Item $SetupExe -Force -ErrorAction SilentlyContinue
  throw "setup.exe too small ($setupSize bytes) — download may be truncated or corrupted. " +
        "Check network connectivity."
}

# --- Step 2: Run setup.exe /configure (fully silent, no UI) ---
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

# --- Step 3: Cleanup on success ---
if ($exitCode -eq 0)
{
  Write-Output "Office 365 installed successfully."
} else
{
  Write-Output "ODT files left at: $OdtDir (for retry/debugging)"
  throw "Office setup failed with exit code $exitCode. Check ODT logs in %TEMP% for details."
}
