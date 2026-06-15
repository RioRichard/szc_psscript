function Install-App
{
  [CmdletBinding()]
  param (
    [String]$Name,
    [String]$PackageName,
    [String]$PackageManager,
    [String]$Custom
  )
  try
  {
    $Command = " winget install -e --id $PackageName --accept-package-agreements --accept-source-agreements -h"
    if ($Custom)
    {
      $Command += "--custom /configure $Custom"
    }

    Start-Process powershell -Verb runAs -ArgumentList "-NoExit", "-NoProfile", "-Command", "$Command"
    
  } catch
  {
    Write-Error "Error when install: $Name"
  } finally
  {
    Write-Host "Installed app $Name"
  }
  
}
