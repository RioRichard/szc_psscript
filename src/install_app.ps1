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
    
    $Command = @("install","-e","--id","$PackageName ","--accept-package-agreements ","--accept-source-agreements ","-h ")
    if (![String]::IsNullOrWhiteSpace($Custom))
    {
      $Command += "--custom /configure $Custom"
    }

    Write-Host "winget $Command"
    winget $Command
  } catch
  {
    Write-Error "Error when install: $Name"
  } finally
  {
    Write-Host "Installed app $Name"
  }
  
}
