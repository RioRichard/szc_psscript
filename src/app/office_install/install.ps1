$Url      = "https://go.microsoft.com/fwlink/?linkid=2264705&clcid=0x409&culture=en-us&country=us"
$CacheDir = "C:\ProgramData\SZC\InstallCache"
$OfficeXMLSrc = Join-Path $PSScriptRoot "OfficeCustom.xml"

# Ensure cache directory exists
New-Item -ItemType Directory -Force -Path $CacheDir | Out-Null

# Copy the XML to the cache dir (guaranteed space-free path) so the ODT can always find it
$OfficeXML = Join-Path $CacheDir "OfficeCustom.xml"
Copy-Item -Path $OfficeXMLSrc -Destination $OfficeXML -Force

$Installer = Join-Path $CacheDir "OfficeSetup.exe"

Write-Output "Downloading Office Click-to-Run bootstrapper..."
try
{
  Invoke-WebRequest -Uri $Url -OutFile $Installer -UseBasicParsing
} catch
{
  throw "Failed to download Office installer: $($_.Exception.Message)"
}

Write-Output "Starting Office deployment with config: $OfficeXML"
# NOTE: Start-Process joins ArgumentList elements with spaces, so quote the path
# to guard against spaces in the path. Also the XML is now in $CacheDir (no spaces).
$Proc = Start-Process `
  -FilePath $Installer `
  -ArgumentList @("/configure", "`"$OfficeXML`"") `
  -NoNewWindow `
  -PassThru `
  -Wait

$exitCode = $Proc.ExitCode
Write-Output "Office setup exited with code: $exitCode"

# Clean up installer only on success
if ($exitCode -eq 0)
{
  Remove-Item $Installer -Force -ErrorAction SilentlyContinue
  Write-Output "Office installation completed successfully."
} else
{
  Write-Output "Installer left at: $Installer (for retry/debugging)"
  throw "Office setup failed with exit code $exitCode. Check logs in %TEMP% for details."
}
