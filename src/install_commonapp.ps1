. "$PSScriptRoot\install_app.ps1"

# Load app definitions from config.json
$_config = Get-Content "$PSScriptRoot\config.json" -Raw | ConvertFrom-Json

$CommonApps = foreach ($app in $_config.apps) {
  # Expand customScript relative path into a full powershell argument array at load time
  $custom = ""
  if ($app.customScript) {
    $scriptPath = Join-Path $PSScriptRoot $app.customScript
    $custom = @("-ExecutionPolicy", "ByPass", $scriptPath)
  }

  @{
    Id             = $app.id
    Name           = $app.name
    Package        = $app.package
    PackageManager = $app.packageManager
    Custom         = $custom
  }
}

function Install-CommonApps
{
  foreach ($App in $CommonApps)
  {
    Install-App -Name $App.Name -PackageName $App.Package -PackageManager $App.PackageManager -Custom $App.Custom
  }
}
