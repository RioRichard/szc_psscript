function Install-App
{
  [CmdletBinding()]
  param (
    [String]$Name,
    [String]$PackageName,
    [String]$PackageManager
  )
  try
  {
    winget install $PackageName --accept-package-agreements --accept-source-agreements -h
  } catch
  {
    Write-Error "Error when install: $Name"
  } finally
  {
    Write-Host "Installed app $Name"
  }
  
}
