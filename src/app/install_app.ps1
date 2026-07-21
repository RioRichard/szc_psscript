function Install-App
{
  [CmdletBinding()]
  param (
    [String]$Name,
    [String]$PackageName,
    [String]$PackageManager,
    [String[]]$Custom
  )

  # Determine the command arguments
  if ($Custom -and $Custom.Count -gt 0)
  {
    $Command = $Custom
  }
  else
  {
    $Command = @("install", "-e", "--id", "$PackageName", "--accept-package-agreements", "--accept-source-agreements", "-h")
  }

  Write-Host "Running: $PackageManager $($Command -join ' ')"

  # Use call operator; errors from child process or thrown exceptions propagate to the caller
  & $PackageManager @Command

  if ($LASTEXITCODE -and $LASTEXITCODE -ne 0)
  {
    throw "'$Name' installer exited with code $LASTEXITCODE."
  }

  Write-Host "Successfully installed: $Name"
}
