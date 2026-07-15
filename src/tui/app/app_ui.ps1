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
    $selectAll = $CommonApps.Count + 1
    $selectNone = $CommonApps.Count + 2
    $goBack = $CommonApps.Count + 3
    Write-Host "  $selectAll. Select All"
    Write-Host "  $selectNone. Deselect All"
    Write-Host "  $goBack. Return to Main Menu"
    Write-Footer

    $actionInput = (Read-Host "Choose (1-$goBack)").Trim()
    $val = 0

    if ([int]::TryParse($actionInput, [ref]$val))
    {
      if ($val -ge 1 -and $val -le $CommonApps.Count)
      {
        $app = $CommonApps[$val - 1]
        $script:selectedApps[$app.Id] = !$script:selectedApps[$app.Id]
        $script:currentDepartmentName = "Custom"
      } elseif ($val -eq $selectAll)
      {
        foreach ($app in $CommonApps)
        { $script:selectedApps[$app.Id] = $true
        }
        $script:currentDepartmentName = "Custom"
      } elseif ($val -eq $selectNone)
      {
        foreach ($app in $CommonApps)
        { $script:selectedApps[$app.Id] = $false
        }
        $script:currentDepartmentName = "Custom"
      } elseif ($val -eq $goBack)
      {
        return
      } else
      {
        Write-Host "Invalid option, press Enter to try again..." -ForegroundColor Red
        Read-Host | Out-Null
      }
    } else
    {
      Write-Host "Please enter a number only. Press Enter to try again..." -ForegroundColor Red
      Read-Host | Out-Null
    }
  }
}
