# --- Ensure we are running as Administrator ---
# Almost all operations (winget, installers, printer setup) require elevation.
# If not elevated, re-launch this script with a UAC prompt and exit the current instance.
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator"))
{
  Write-Host "This tool requires Administrator privileges. Requesting elevation..." -ForegroundColor Yellow
  try
  {
    Start-Process powershell.exe `
      -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" `
      -Verb RunAs
  }
  catch
  {
    Write-Host "Failed to elevate: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "Please right-click PowerShell and select 'Run as Administrator'." -ForegroundColor Yellow
    Read-Host "Press Enter to exit"
  }
  exit
}

. "$PSScriptRoot/src/tui/tui.ps1"

Start-Tui

Write-Host ""
Write-Host "Session ended. Press Enter to close this window..." -ForegroundColor DarkGray
Read-Host | Out-Null
