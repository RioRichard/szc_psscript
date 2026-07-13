. "$PSScriptRoot/install_printer.ps1"

# Load printer definitions from config.json
$_config = Get-Content "$PSScriptRoot\config.json" -Raw | ConvertFrom-Json

$Printers = foreach ($printer in $_config.printers) {
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
