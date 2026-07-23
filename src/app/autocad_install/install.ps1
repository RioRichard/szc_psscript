$CacheDir  = "C:\ProgramData\SZC\InstallCache\autocad"
$SetupExe  = Join-Path $CacheDir "Setup.exe"

Write-Host "Checking for AutoCAD LT installation package..."

if (-not (Test-Path $SetupExe)) {
    Write-Host "WARNING: AutoCAD LT setup payload not found at: $SetupExe"
    Write-Host "To deploy AutoCAD LT, place your Autodesk custom deployment files in: $CacheDir"
    Write-Host "Skipping AutoCAD LT installation."
    return
}

Write-Host "Found AutoCAD LT setup package at: $SetupExe"
Write-Host "Executing silent AutoCAD LT installation..."

$process = Start-Process -FilePath $SetupExe -ArgumentList "-q" -NoNewWindow -PassThru -Wait

if ($process.ExitCode -ne 0) {
    throw "AutoCAD LT installation failed with exit code: $($process.ExitCode)"
}

Write-Host "AutoCAD LT installed successfully."
