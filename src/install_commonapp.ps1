. "$PSScriptRoot\install_app.ps1"
$CommonApps = @(
  @{
    Name = "Unikey"
    Package = "Unikey.Unikey"
    PackageManager = "winget"
    Custom = ""
  },
  @{
    Name = "Viber"
    Package = "Rakuten.Viber"
    PackageManager = "winget"
    Custom = ""
  },
  @{
    Name = "Zalo"
    Package = "VNGCorp.Zalo"
    PackageManager = "winget"
    Custom = ""
  },
  @{
    Name = "Microsoft Office"
    Package = ""
    PackageManager = ""
    Custom = @("powershell","-ExecutionPolicy","ByPass","$PSScriptRoot/office_install/install.ps1")
  },
  @{
    Name = "Microsoft OneDrive"
    Package = "Microsoft.OneDrive"
    PackageManager = "winget"
    Custom = ""
  },
  @{
    Name = "Chrome"
    Package = "Google.Chrome"
    PackageManager = "winget"
    Custom = ""
  },
  @{
    Name = "7 Zip"
    Package = "7zip.7zip"
    PackageManager = "winget"
    Custom = ""
  },
  @{
    Name = "VCRedist (x64)"
    Package = "Microsoft.VCRedist.2015+.x64"
    PackageManager = "winget"
    Custom = ""
  },
  @{
    Name = "VCRedist (x86)"
    Package = "Microsoft.VCRedist.2015+.x86"
    PackageManager = "winget"
    Custom = ""
  }
)

function Install-CommonApps
{
  foreach ($App in $CommonApps)
  {
    Install-App -Name $App.Name -PackageName $App.Package -PackageManager $App.PackageManager -Custom $App.Custom
  }
}
