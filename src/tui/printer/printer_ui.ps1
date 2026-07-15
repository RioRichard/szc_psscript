function Show-PrinterSelectionMenu
{
  while ($true)
  {
    Clear-Host
    Write-Header "SELECT PRINTERS TO INSTALL"

    if ($Printers.Count -eq 0)
    {
      Write-Host "  No printers configured yet." -ForegroundColor Yellow
      Write-Divider
      Write-Host "  1. Return to Main Menu"
      Write-Footer

      $actionInput = (Read-Host "Choose (1)").Trim()
      if ($actionInput -eq "1") { return }
      continue
    }

    for ($i = 0; $i -lt $Printers.Count; $i++)
    {
      $printer = $Printers[$i]
      $checkbox = if ($script:selectedPrinters[$printer.Id])
      { "[X]"
      } else
      { "[ ]"
      }
      $num = ($i + 1).ToString().PadLeft(2)
      Write-Host "  $num. $checkbox $($printer.Name) ($($printer.Url))"
    }

    Write-Divider
    $selectAll = $Printers.Count + 1
    $selectNone = $Printers.Count + 2
    $goBack = $Printers.Count + 3
    Write-Host "  $selectAll. Select All"
    Write-Host "  $selectNone. Deselect All"
    Write-Host "  $goBack. Return to Main Menu"
    Write-Footer

    $actionInput = (Read-Host "Choose (1-$goBack)").Trim()
    $val = 0

    if ([int]::TryParse($actionInput, [ref]$val))
    {
      if ($val -ge 1 -and $val -le $Printers.Count)
      {
        $printer = $Printers[$val - 1]
        $script:selectedPrinters[$printer.Id] = !$script:selectedPrinters[$printer.Id]
        $script:currentDepartmentName = "Custom"
      } elseif ($val -eq $selectAll)
      {
        foreach ($printer in $Printers)
        { $script:selectedPrinters[$printer.Id] = $true
        }
        $script:currentDepartmentName = "Custom"
      } elseif ($val -eq $selectNone)
      {
        foreach ($printer in $Printers)
        { $script:selectedPrinters[$printer.Id] = $false
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
