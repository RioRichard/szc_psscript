# .NET Framework 3.5 Installer (includes .NET 2.0 and 3.0)
# Uses DISM to enable the Windows optional feature.
# Requires internet access for Windows Update to download components.

Write-Host "Checking if .NET Framework 3.5 is already enabled..."

$feature = Get-WindowsOptionalFeature -Online -FeatureName "NetFx3" -ErrorAction SilentlyContinue

if ($feature -and $feature.State -eq "Enabled") {
    Write-Host ".NET Framework 3.5 is already enabled. Skipping."
    return
}

Write-Host "Enabling .NET Framework 3.5 (includes .NET 2.0 and 3.0)..."
Write-Host "  This may take a few minutes (downloading from Windows Update)..."

try {
    Enable-WindowsOptionalFeature -Online -FeatureName "NetFx3" -All -NoRestart -ErrorAction Stop
    Write-Host ".NET Framework 3.5 enabled successfully."
} catch {
    # Fallback to DISM if the PowerShell cmdlet fails
    Write-Host "  PowerShell method failed, trying DISM..."
    $dismResult = Start-Process -FilePath "dism.exe" `
        -ArgumentList "/online /Enable-Feature /FeatureName:NetFx3 /All /NoRestart" `
        -NoNewWindow -PassThru -Wait

    if ($dismResult.ExitCode -ne 0) {
        throw ".NET Framework 3.5 installation failed (DISM exit code: $($dismResult.ExitCode)). Ensure internet access is available."
    }
    Write-Host ".NET Framework 3.5 enabled successfully via DISM."
}
