# Load download helper
$_downloadHelper = Join-Path $PSScriptRoot "download_helper.ps1"
if (Test-Path $_downloadHelper) { . $_downloadHelper }

function Install-App
{
  [CmdletBinding()]
  param (
    [String]$Name,
    [String]$PackageName,
    [String]$PackageManager,
    [String]$CustomScript
  )

  if ($CustomScript)
  {
    # Dot-source the script directly in the current process so that:
    #   - any `throw` inside it propagates up to the TUI's try/catch
    #   - all Write-Host / Write-Output appears in the TUI console
    #   - $PSScriptRoot inside the custom script resolves to its own directory
    Write-Host "Running custom script: $CustomScript"
    $scriptDir = Split-Path $CustomScript -Parent
    Push-Location $scriptDir
    try
    {
      . $CustomScript
    }
    finally
    {
      Pop-Location
    }
  }
  else
  {
    $Command = @("install", "-e", "--id", $PackageName,
                 "--accept-package-agreements", "--accept-source-agreements", "-h")
    Write-Host "Running: $PackageManager $($Command -join ' ')"
    & $PackageManager @Command

    if ($LASTEXITCODE -and $LASTEXITCODE -ne 0)
    {
      throw "'$Name' installer exited with code $LASTEXITCODE."
    }
  }

  Write-Host "Successfully installed: $Name"
}
