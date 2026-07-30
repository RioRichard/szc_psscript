. "$PSScriptRoot/install_printer.ps1"

# Load printer definitions from config/printers.json
$printersJsonPath = Join-Path $PSScriptRoot "../config/printers.json"
$_printers = Get-Content $printersJsonPath -Raw | ConvertFrom-Json

$Printers = foreach ($printer in $_printers) {
  @{
    Id        = $printer.id
    Name      = $printer.name
    Url       = $printer.url
    Port      = $printer.port
    Driver    = $printer.driver
    UrlDriver = $printer.urlDriver
  }
}

function Install-BHCommonPrinters
{
  foreach ($Printer in $Printers)
  {
    Install-LocalPrinter -Name $Printer.Name -Url $Printer.Url -Port $Printer.Port -Driver $Printer.Driver -UrlDriver $Printer.UrlDriver
  }
}
