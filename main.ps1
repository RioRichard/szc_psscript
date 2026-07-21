. "$PSScriptRoot/src/tui/tui.ps1"

Start-Tui

Write-Host ""
Write-Host "Session ended. Press Enter to close this window..." -ForegroundColor DarkGray
Read-Host | Out-Null
