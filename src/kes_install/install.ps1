$Url = "https://aes.s.kaspersky-labs.com/endpoints/keswin11/14.0.0.504/vietnamese-INT-21.25.7.504.0.143.0/a0b3932eaa6c05bcb1ae932d500116a2/keswin_14.0.0.504_vi_aes56.exe"
$CacheDir = "C:\ProgramData\SZC\InstallCache"
$AppName = "kes.exe"

New-Item `
  -ItemType Directory `
  -Force `
  -Path $CacheDir | Out-Null

$Installer = Join-Path $CacheDir $AppName 

Write-Host "Downloading Kaspersky Endpoint Security..."
Invoke-WebRequest `
  -Uri $Url `
  -OutFile $Installer

$ArgurmentList = @("/s", "/pEULA=1", "/pPRIVACYPOLICY=1")

Write-Host "Running Kaspersky installation silently..."
$Proc = Start-Process `
  -FilePath $Installer `
  -ArgumentList $ArgurmentList `
  -PassThru `
  -Wait

Write-Host "Kaspersky installation completed with exit code: $($Proc.ExitCode)"
Write-Output $Proc.ExitCode

Write-Host "Cleaning up installer..."
Remove-Item $Installer -Force
