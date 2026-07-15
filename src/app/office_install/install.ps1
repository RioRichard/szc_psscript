$Url      = "https://go.microsoft.com/fwlink/?linkid=2264705&clcid=0x409&culture=en-us&country=us"
$CacheDir = "C:\ProgramData\SZC\InstallCache"
$OfficeXML = Join-Path $PSScriptRoot "OfficeCustom.xml"

# Ensure cache directory exists
New-Item -ItemType Directory -Force -Path $CacheDir | Out-Null

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
$Proc = Start-Process `
  -FilePath $Installer `
  -ArgumentList @("/configure", $OfficeXML) `
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
