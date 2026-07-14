function Install-App
{
  [CmdletBinding()]
  param (
    [String]$Name,
    [String]$PackageName,
    [String]$PackageManager,
    $Custom
  )
  try
  {
    if (![String]::IsNullOrWhiteSpace($Custom))
    {
      $Command = $Custom
    }
    else
    {
      $Command = @("install", "-e", "--id", "$PackageName", "--accept-package-agreements", "--accept-source-agreements", "-h")
    }

    Write-Host "Running: $PackageManager $Command"
    & $PackageManager $Command
  } catch
  {
    Write-Error "Error when install: $Name"
  } finally
  {
    Write-Host "Installed app $Name"
  }
  
}
