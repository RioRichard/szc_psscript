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
    $Command = @("winget","install","--e","--id","$PackageName","--accept-package-agreements","--accept-source-agreements","-h")
    if (![String]::IsNullOrWhiteSpace($Custom))
    {
      $Command = $Custom
    }

    & $Command

    if ($Temp)
    {
      $Temp | Set-Content $OfficeCustomxml
    }
  } catch
  {
    Write-Error "Error when install: $Name"
  } finally
  {
    Write-Host "Installed app $Name"
  }
  
}
