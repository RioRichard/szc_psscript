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
    $Temp = ""
    $OfficeCustomxml = "$PSScriptRoot/OfficeCustom.xml"
    $Command = @("install","-e","--id","$PackageName","--accept-package-agreements","--accept-source-agreements","-h")
    if (![String]::IsNullOrWhiteSpace($Custom))
    {
      if ($PackageName -eq 'Microsoft.Office')
      {
        $Temp = (Get-Content $OfficeCustomxml)
        (Get-Content $OfficeCustomxml) -replace 'OfficeCustom.xml', "$PSScriptRoot/OfficeCustom.xml" | Set-Content $OfficeCustomxml
      }
      $Command = @("install","-m " ,"$Custom")
    }
    $Temp | Set-Content $OfficeCustomxml

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
