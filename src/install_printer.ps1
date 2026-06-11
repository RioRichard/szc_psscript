
function Install-LocalPrinter{
  [CmdletBinding(SupportShouldProcess)]
  param (
    [Parameter(Mandatory)]
    [string] $Name,

    [Parameter(Mandatory)]
    [string] $Url,
    
    [string] $Port,

    [string] $Driver,
  )

  try {
    $ExistingPrinterByName = Get-Printer -Name $Name -ErrorAction SilentlyContinue

    if ($ExistingPrinterByName) {
      Write-Host "Printer already exist: $Name"
      return
    }


    if ($PSCmdlet.ShouldProcess($Name, "Installing Printer $Name at $Url")) {
      if (!$Port -and !$Driver) {
        Add-Printer -Name $Name -DeviceUrl $Url -ErrorAction Stop
      }else {
      #   if ($Port){
      #     $ExistingPort = Get-PrinterPort -Name "IP_$Name" -ErrorAction SilentlyContinue
      #     if (!$ExistingPort){
      #
      #     }
      #   }
      #
      # }
      Write-Warning "Add Port and Driver"
    }
  }
  catch {
      Write-Error "Error when install $Name"
      Write-Error "Reason: ${$_.Exception.Message}"
  }
  
    
}
