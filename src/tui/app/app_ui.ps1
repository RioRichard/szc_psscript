function Show-AppSelectionMenu
{
  while ($true)
  {
    Clear-Host
    Write-Header "SELECT APPLICATIONS TO INSTALL"
    
    for ($i = 0; $i -lt $CommonApps.Count; $i++)
    {
      $app = $CommonApps[$i]
      $checkbox = if ($script:selectedApps[$app.Id])
      { "[X]" 
      } else
      { "[ ]" 
      }
      $num = ($i + 1).ToString().PadLeft(2)
      Write-Host "  $num. $checkbox $($app.Name)"
    }
    
    Write-Divider
    Write-Host "  Enter a number (1-$($CommonApps.Count)) to toggle"
    Write-Host "  Enter 'A' to select All, 'N' to select None"
    Write-Host "  Enter 'Q' to Return to Main Menu"
    Write-Footer
    
    $actionInput = (Read-Host "Action").Trim().ToUpper()
    
    if ($actionInput -eq "Q")
    {
      return
    } elseif ($actionInput -eq "A")
    {
      foreach ($app in $CommonApps)
      { $script:selectedApps[$app.Id] = $true 
      }
      $script:currentDepartmentName = "Custom"
    } elseif ($actionInput -eq "N")
    {
      foreach ($app in $CommonApps)
      { $script:selectedApps[$app.Id] = $false 
      }
      $script:currentDepartmentName = "Custom"
    } else
    {
      $val = 0
      if ([int]::TryParse($actionInput, [ref]$val) -and $val -ge 1 -and $val -le $CommonApps.Count)
      {
        $app = $CommonApps[$val - 1]
        $script:selectedApps[$app.Id] = !$script:selectedApps[$app.Id]
        $script:currentDepartmentName = "Custom"
      } else
      {
        Write-Host "Invalid option, press Enter to try again..." -ForegroundColor Red
        Read-Host | Out-Null
      }
    }
  }
}
