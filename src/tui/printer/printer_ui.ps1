function Show-PrinterSelectionMenu
{
  while ($true)
  {
    Clear-Host
    Write-Header "SELECT PRINTERS TO INSTALL"
    
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
    Write-Host "  Enter a number (1-$($Printers.Count)) to toggle"
    Write-Host "  Enter 'A' to select All, 'N' to select None"
    Write-Host "  Enter 'Q' to Return to Main Menu"
    Write-Footer
    
    $actionInput = (Read-Host "Action").Trim().ToUpper()
    
    if ($actionInput -eq "Q")
    {
      return
    } elseif ($actionInput -eq "A")
    {
      foreach ($printer in $Printers)
      { $script:selectedPrinters[$printer.Id] = $true 
      }
      $script:currentDepartmentName = "Custom"
    } elseif ($actionInput -eq "N")
    {
      foreach ($printer in $Printers)
      { $script:selectedPrinters[$printer.Id] = $false 
      }
      $script:currentDepartmentName = "Custom"
    } else
    {
      $val = 0
      if ([int]::TryParse($actionInput, [ref]$val) -and $val -ge 1 -and $val -le $Printers.Count)
      {
        $printer = $Printers[$val - 1]
        $script:selectedPrinters[$printer.Id] = !$script:selectedPrinters[$printer.Id]
        $script:currentDepartmentName = "Custom"
      } else
      {
        Write-Host "Invalid option, press Enter to try again..." -ForegroundColor Red
        Read-Host | Out-Null
      }
    }
  }
}
