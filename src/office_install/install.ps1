

$Url = "https://go.microsoft.com/fwlink/?linkid=2264705&clcid=0x409&culture=en-us&country=us"
$CacheDir = "C:\ProgramData\SZC\InstallCache"

New-Item `
  -ItemType Directory `
  -Force `
  -Path $CacheDir | Out-Null

$Installer = Join-Path $CacheDir "OfficeSetup.exe"

Invoke-WebRequest `
  -Uri $Url `
  -OutFile $Installer

$Proc = Start-Process `
  -FilePath $Installer `
  -ArgumentList @("/quiet","/configure","$PSScriptRoot/OfficeCustom.xml") `
  -PassThru `
  -Wait

Write-Output $Proc.ExitCode

Remove-Item $Installer -Force
