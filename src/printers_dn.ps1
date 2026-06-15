. "$PSScriptRoot\install_printer.ps1"
$Printers = @(
  @{
    Name = "HP 4003 DN"
    Url = "192.168.3.21"
  },
  @{
    Name = "Brother T4500DW BH"
    Url = "192.168.3.20"
  },
  @{
    Name = "Ricoh MP 3555 BH (Photocopy)"
    Url = "192.168.3.23"
  },
  @{
    Name = "EPSON L1800 BH"
    Url= "192.168.3.21"
    Port = "L1800"
    Driver = "Epson L1800"
    UrlDriver = "https://ftp.hp.com/pub/softlib/software13/printers/LJ4001-4004/V4_DriveronlyWebpack-54.5.5370-LJ4001-4004_V4_DriveronlyWebpack.exe"
  }
)
function Install-BHCommonPrinters
{
  foreach ($Printer in $Printers)
  {
    Install-LocalPrinter -Name $Printer.Name -Url $Printer.Url -Port $Printer.Port -Driver $Printer.Driver -UrlDriver $Printer.UrlDriver
  }
}
