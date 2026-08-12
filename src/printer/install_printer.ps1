<#
.SYNOPSIS
Installs a local printer in one of three modes: TCP/IP (zero-config inbox driver), TCP/IP + custom driver, or LPR + custom driver.

.DESCRIPTION
Handles 3 printer installation modes:
1. Zero-config / Default mode (no Port, no Driver specified): Creates Standard TCP/IP port (IP_<Url>)
   and binds to built-in Windows driver (Microsoft PCL6 Class Driver / Microsoft IPP Class Driver).
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
        [string[]]$DriverInstallArgs,
        [string]$IppPath,
        [string]$PaperSize,
        [string]$Duplex
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
            # Try wildcard match in case driver name in Windows differs slightly from config
            $allDrivers = Get-PrinterDriver -ErrorAction SilentlyContinue
            $wildcardMatch = $allDrivers | Where-Object { $_.Name -like "*$Driver*" -or $Driver -like "*$($_.Name)*" } | Select-Object -First 1
            if ($wildcardMatch) {
                $Driver = $wildcardMatch.Name
                $existingDriver = $wildcardMatch
            }
        }

        if ($existingDriver) {
            Write-Host "  Driver '$Driver' is already installed in Windows." -ForegroundColor Green
        } else {
            if (-not $DriverUrl) {
                throw "Driver '$Driver' is not installed and no DriverUrl provided."
            }

            $fileName = Split-Path $DriverUrl -Leaf
            $cacheDir = "C:\ProgramData\SZC\InstallCache\Drivers"
            if (-not (Test-Path $cacheDir)) {
                New-Item -ItemType Directory -Path $cacheDir -Force | Out-Null
            }
            $DriverPath = Join-Path $cacheDir $fileName

            if ((Test-Path $DriverPath) -and (Get-Item $DriverPath).Length -gt 1024) {
                Write-Host "  Found cached driver package ($fileName). Skipping download." -ForegroundColor Green
            } else {
                if (Test-Path $DriverPath) { Remove-Item $DriverPath -Force -ErrorAction SilentlyContinue }
                Start-MultiDownload -Url $DriverUrl -OutFile $DriverPath -ActivityName "Downloading $Driver driver"
            }
            
            Write-Host "  Installing driver for $Driver..."

            # Check if driver needs extraction
            $needsExtraction = ($DriverPath -match "\.(exe|zip|7z)$")

            # Find 7-Zip binary if available for INF extraction
            $7zExe = $null
            if ($needsExtraction) {
                $7zExe = (Get-Command "7z.exe" -ErrorAction SilentlyContinue).Source
                if (-not $7zExe) {
                    $possible7z = @(
                        "$env:ProgramFiles\7-Zip\7z.exe",
                        "${env:ProgramFiles(x86)}\7-Zip\7z.exe"
                    ) | Where-Object { Test-Path $_ } | Select-Object -First 1
                    if ($possible7z) { $7zExe = $possible7z }
                }

                if (-not $7zExe) {
                    throw "7-Zip is required to extract the driver package for '$Driver' but was not found. Please install 7-Zip first (winget install -e --id 7zip.7zip)."
                }
            }

            $installedViaInf = $false
            if ($7zExe -and $needsExtraction) {
                $extractDir = Join-Path $cacheDir "extracted_$([System.IO.Path]::GetFileNameWithoutExtension($fileName))"
                if (-not (Test-Path $extractDir)) {
                    New-Item -ItemType Directory -Path $extractDir -Force | Out-Null
                }

                Write-Host "Extracting driver package using 7-Zip..."
                & $7zExe x -y "-o$extractDir" $DriverPath | Out-Null

                $infFiles = Get-ChildItem -Path $extractDir -Filter "*.inf" -Recurse -ErrorAction SilentlyContinue
                if ($infFiles) {
                    Write-Host "Found $($infFiles.Count) INF file(s). Staging driver via Pnputil..."
                    foreach ($inf in $infFiles) {
                        & pnputil.exe /add-driver "$($inf.FullName)" /install | Out-Null
                    }

                    Add-PrinterDriver -Name $Driver -ErrorAction SilentlyContinue
                    $existingDriverCheck = Get-PrinterDriver -Name $Driver -ErrorAction SilentlyContinue
                    if ($existingDriverCheck) {
                        $installedViaInf = $true
                        Write-Host "Driver '$Driver' successfully installed via INF staging."
                    }
                }
            }

            if (-not $installedViaInf) {
                if ($needsExtraction) {
                    throw "Failed to install driver '$Driver' via INF staging. No suitable .inf files found in extracted package."
                }
                Write-Host "Running driver installer executable..."
                $proc = Start-Process -FilePath $DriverPath -ArgumentList $DriverInstallArgs -PassThru -Wait
                if ($proc.ExitCode -ne 0) {
                    throw "Driver installer exited with code $($proc.ExitCode)."
                }
                Add-PrinterDriver -Name $Driver -ErrorAction SilentlyContinue
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
                Add-PrinterPort -Name $Port -PrinterHostAddress $Url -LprQueueName $LprQueue -LprByteCounting -ErrorAction Stop
            }
        } else {
            throw "Invalid PortType specified. Must be 'tcpip' or 'lpr'."
        }

        Add-Printer -Name $Name -PortName $Port -DriverName $Driver -ErrorAction Stop
    } else {
        # Zero-config / Default mode: Create Standard TCP/IP port and use built-in Windows class driver
        $portName = if ($Port) { $Port } else { "IP_$Url" }
        $existingPort = Get-PrinterPort -Name $portName -ErrorAction SilentlyContinue
        if (-not $existingPort) {
            Add-PrinterPort -Name $portName -PrinterHostAddress $Url -ErrorAction Stop
        }

        # Select best built-in Windows driver (prefer IPP Class Driver on modern systems, fall back to PCL6)
        $inboxDrivers = @("Microsoft IPP Class Driver", "Microsoft PCL6 Class Driver", "Generic / Text Only")
        $selectedDriver = $null
        foreach ($drv in $inboxDrivers) {
            $checkDrv = Get-PrinterDriver -Name $drv -ErrorAction SilentlyContinue
            if (-not $checkDrv) {
                Add-PrinterDriver -Name $drv -ErrorAction SilentlyContinue
                $checkDrv = Get-PrinterDriver -Name $drv -ErrorAction SilentlyContinue
            }
            if ($checkDrv) {
                $selectedDriver = $drv
                break
            }
        }

        if (-not $selectedDriver) {
            throw "No suitable built-in printer driver (Microsoft PCL6 Class Driver / Microsoft IPP Class Driver) found on this system."
        }

        Add-Printer -Name $Name -PortName $portName -DriverName $selectedDriver -ErrorAction Stop
    }

    # Default PaperSize to "A4" if omitted, and apply configuration (PaperSize / Duplex)
    if (-not $PaperSize) {
        $PaperSize = "A4"
    }

    $configArgs = @{ PrinterName = $Name; PaperSize = $PaperSize }
    if ($Duplex) {
        $normDuplex = switch -Exact ($Duplex.ToLower()) {
            "longedge"          { "TwoSidedLongEdge" }
            "shortedge"         { "TwoSidedShortEdge" }
            "onesided"          { "OneSided" }
            "twosidedlongedge"  { "TwoSidedLongEdge" }
            "twosidedshortedge" { "TwoSidedShortEdge" }
            default             { $Duplex }
        }
        $configArgs['DuplexingMode'] = $normDuplex
    }

    Write-Host "  Applying print configuration for '$Name' (PaperSize: $PaperSize$(if ($Duplex) { ", Duplex: $Duplex" }))..."
    try {
        Set-PrintConfiguration @configArgs -ErrorAction Stop
        Write-Host "  Print configuration applied." -ForegroundColor Green
    } catch {
        Write-Host "  Warning: Could not set print configuration ($($_.Exception.Message))" -ForegroundColor Yellow
    }
}
