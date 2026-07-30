function Write-Header ($Title)
{
  Write-Host "==================================================" -ForegroundColor Cyan
  Write-Host "         $Title" -ForegroundColor Green
  Write-Host "==================================================" -ForegroundColor Cyan
}

function Write-Footer
{
  Write-Host "==================================================" -ForegroundColor Cyan
}

function Write-Divider
{
  Write-Host "--------------------------------------------------"
}

function Show-PressEnterToContinue ($Message = "Press Enter to return to main menu...")
{
  Write-Host $Message
  Read-Host | Out-Null
}
