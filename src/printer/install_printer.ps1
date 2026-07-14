function Install-LocalPrinter
{
  [CmdletBinding(SupportsShouldProcess)]
  param (
    [Parameter(Mandatory)]
    [string] $Name,

    [Parameter(Mandatory)]
    [string] $Url,
    
    [string] $Port,

    [string] $Driver,
    
    [string] $UrlDriver
  )

  try
  {
    $ExistingPrinterByName = Get-Printer -Name $Name -ErrorAction SilentlyContinue

    if ($ExistingPrinterByName)
    {
      Write-Host "Printer already exists: $Name"
      return
    }

    if ($PSCmdlet.ShouldProcess($Name, "Installing Printer $Name at $Url"))
    {
      if (!$Port -and !$Driver)
      {
        Write-Host "Adding printer $Name via DeviceUrl $Url..."
        Add-Printer -Name $Name -DeviceUrl $Url -ErrorAction Stop
      } else
      {
        if ($Port)
        {
          $ExistingPort = Get-PrinterPort -Name $Port -ErrorAction SilentlyContinue
          if (!$ExistingPort)
          {
            Write-Host "Creating Printer Port: $Port at $Url..."
            Add-PrinterPort -Name $Port -PrinterHostAddress $Url -ErrorAction Stop
          }
        }

        if ($Driver)
        {
          $ExistingDriver = Get-PrinterDriver -Name $Driver -ErrorAction SilentlyContinue
          if (!$ExistingDriver)
          {
            if ($UrlDriver)
            {
              Write-Host "Downloading printer driver from $UrlDriver..."
              $TempDir = "C:\ProgramData\SZC\InstallCache\Drivers"
              New-Item -ItemType Directory -Force -Path $TempDir | Out-Null
              $DriverFileName = Split-Path $UrlDriver -Leaf
              $DriverPath = Join-Path $TempDir $DriverFileName
              Invoke-WebRequest -Uri $UrlDriver -OutFile $DriverPath

              Write-Host "Running driver installer: $DriverFileName..."
              $Proc = Start-Process -FilePath $DriverPath -ArgumentList "/s", "/q", "/silent" -PassThru -Wait
              Write-Host "Driver installer finished with exit code: $($Proc.ExitCode)"
              Remove-Item $DriverPath -Force
            }
            else
            {
              Write-Warning "Driver '$Driver' is not installed, and no UrlDriver was provided."
            }
          }
        }

        Write-Host "Adding printer $Name with Port '$Port' and Driver '$Driver'..."
        $PrinterParams = @{
          Name = $Name
          PortName = $Port
        }
        if ($Driver)
        {
          $PrinterParams.DriverName = $Driver
        }
        Add-Printer @PrinterParams -ErrorAction Stop
      }
    }
  
  } catch
  {
    Write-Error "Error when installing printer $Name"
    Write-Error "Reason: $($_.Exception.Message)"
  } finally
  {
    Write-Host "Finished attempt to install printer $Name"
  }
}
