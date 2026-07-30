<#
.SYNOPSIS
Installs a local printer in one of three modes: IPP, TCP/IP, or LPR.

.DESCRIPTION
Handles 3 printer installation modes:
1. IPP mode (no Port, no Driver specified): Uses Add-Printer with -DeviceUrl.
2. TCP/IP port + driver mode (PortType = 'tcpip'): Creates port with Add-PrinterPort -PrinterHostAddress.
3. LPR port + driver mode (PortType = 'lpr'): Creates port with Add-PrinterPort -LprHostAddress and -LprQueueName.
#>

. (Join-Path (Split-Path $MyInvocation.MyCommand.Path -Parent) "../app/download_helper.ps1")

function Install-LocalPrinter {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [string]$Name,
        
        [Parameter(Mandatory=$true)]
        [string]$Url,
        
        [string]$Port,
        [string]$PortType,
        [string]$LprQueue,
        [string]$Driver,
        [string]$DriverUrl,
        [string[]]$DriverInstallArgs
    )

    $existingPrinter = Get-Printer -Name $Name -ErrorAction SilentlyContinue
    if ($existingPrinter) {
        Write-Host "Printer '$Name' already exists. Skipping."
        return
    }

    if ($PortType -or $Driver) {
        if (-not $Driver) {
            throw "Driver name must be specified when using a port."
        }

        $existingDriver = Get-PrinterDriver -Name $Driver -ErrorAction SilentlyContinue
        if (-not $existingDriver) {
            if (-not $DriverUrl) {
                throw "Driver '$Driver' is not installed and no DriverUrl provided."
            }

            $fileName = Split-Path $DriverUrl -Leaf
            $cacheDir = "C:\ProgramData\SZC\InstallCache\Drivers"
            if (-not (Test-Path $cacheDir)) {
                New-Item -ItemType Directory -Path $cacheDir -Force | Out-Null
            }
            $DriverPath = Join-Path $cacheDir $fileName

            Start-MultiDownload -Url $DriverUrl -OutFile $DriverPath -ActivityName "Downloading $Driver driver"
            
            Write-Host "Installing driver for $Driver..."
            $proc = Start-Process -FilePath $DriverPath -ArgumentList $DriverInstallArgs -PassThru -Wait
            if ($proc.ExitCode -ne 0) {
                throw "Driver installer exited with code $($proc.ExitCode)."
            }
        }

        if ($PortType -eq 'tcpip') {
            $existingPort = Get-PrinterPort -Name $Port -ErrorAction SilentlyContinue
            if (-not $existingPort) {
                Add-PrinterPort -Name $Port -PrinterHostAddress $Url -ErrorAction Stop
            }
        } elseif ($PortType -eq 'lpr') {
            $existingPort = Get-PrinterPort -Name $Port -ErrorAction SilentlyContinue
            if (-not $existingPort) {
                Add-PrinterPort -Name $Port -PrinterHostAddress $Url -LprHostAddress $Url -LprQueueName $LprQueue -LprByteCounting -ErrorAction Stop
            }
        } else {
            throw "Invalid PortType specified. Must be 'tcpip' or 'lpr'."
        }

        Add-Printer -Name $Name -PortName $Port -DriverName $Driver -ErrorAction Stop
    } else {
        Add-Printer -Name $Name -DeviceUrl "http://$Url/ipp/print" -ErrorAction Stop
    }
}
