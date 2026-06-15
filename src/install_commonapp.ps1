. "$PSScriptRoot/src/install_app.ps1"
$CommonApps = @(
  @{
    Name = "Unikey"
    Package = "unikey.unikey"
    PackageManager = "winget"
  },
  @{
    Name = "Viber"
    Package = "Rakurten.Viber"
    PackageManager = "winget"
  },
  @{
    Name = "Zalo"
    Package = "VNGCorp.Zalo"
    PackageManager = "winget"
  },
  @{
    Name = "Chrome"
    Package = "Chrome"
    PackageManager = "winget"
  },
  @{
    Name = "VCRedist (x64)"
    Package = "Microsoft.VCRedist.2015+.x64"
    PackageManager = "winget"
  },
  @{
    Name = "VCRedist (x86)"
    Package = "Microsoft.VCRedist.2015+.x86"
    PackageManager = "winget"
  }
)

function Install-CommonApps
{
  foreach ($App in $CommonApps)
  {
    Install-App -Name $App.Name -Package $App.Package -PackageManager $App.PackageManager
  }
}
