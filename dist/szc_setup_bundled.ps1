# ==========================================================================
# SZC AUTOMATED DEPLOYMENT SUITE - STANDALONE BUNDLED SCRIPT
# Built on: 2026-08-12 15:46:36
# ==========================================================================

# --- Ensure Administrator Privileges ---
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator"))
{
  Write-Host "This tool requires Administrator privileges. Requesting elevation..." -ForegroundColor Yellow
  try
  {
    Start-Process powershell.exe `
      -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" `
      -Verb RunAs
  }
  catch
  {
    Write-Host "Failed to elevate: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "Please right-click PowerShell and select 'Run as Administrator'." -ForegroundColor Yellow
    Read-Host "Press Enter to exit"
  }
  exit
}

# --- EMBEDDED CONFIGURATIONS & ASSETS ---
$script:Embedded_AppsJson = @'
[
  {
    "id": "unikey",
    "name": "UniKey",
    "package": "UniKey.UniKey",
    "packageManager": "winget"
  },
  {
    "id": "stirlingPdf",
    "name": "Stirling PDF",
    "package": "StirlingTools.StirlingPDF",
    "packageManager": "winget"
  },
  {
    "id": "viber",
    "name": "Viber",
    "package": "Rakuten.Viber",
    "packageManager": "winget"
  },
  {
    "id": "zalo",
    "name": "Zalo",
    "package": "VNGCorp.Zalo",
    "packageManager": "winget"
  },
  {
    "id": "office",
    "name": "Microsoft Office",
    "package": "",
    "packageManager": "powershell",
    "customScript": "app/office_install/install.ps1"
  },
  {
    "id": "kes",
    "name": "Kaspersky Endpoint Security",
    "package": "",
    "packageManager": "powershell",
    "customScript": "app/kes_install/install.ps1",
    "dependencies": [
      "7zip"
    ]
  },
  {
    "id": "onedrive",
    "name": "Microsoft OneDrive",
    "package": "Microsoft.OneDrive",
    "packageManager": "winget"
  },
  {
    "id": "ultraviewer",
    "name": "Ultra Viewer",
    "package": "DucFabulous.UltraViewer",
    "packageManager": "winget"
  },
  {
    "id": "chrome",
    "name": "Chrome",
    "package": "Google.Chrome",
    "packageManager": "winget"
  },
  {
    "id": "7zip",
    "name": "7 Zip",
    "package": "7zip.7zip",
    "packageManager": "winget"
  },
  {
    "id": "vcredist_x64",
    "name": "VCRedist (x64)",
    "package": "Microsoft.VCRedist.2015+.x64",
    "packageManager": "winget"
  },
  {
    "id": "vcredist_x86",
    "name": "VCRedist (x86)",
    "package": "Microsoft.VCRedist.2015+.x86",
    "packageManager": "winget"
  },
  {
    "id": "vscode",
    "name": "Visual Studio Code",
    "package": "Microsoft.VisualStudioCode",
    "packageManager": "winget"
  },
  {
    "id": "python",
    "name": "Python 3",
    "package": "Python.Python.3.12",
    "packageManager": "winget"
  },
  {
    "id": "nodejs",
    "name": "Node.js LTS",
    "package": "OpenJS.NodeJS.LTS",
    "packageManager": "winget"
  },
  {
    "id": "qgis",
    "name": "QGIS",
    "package": "OSGeo.QGIS",
    "packageManager": "winget"
  },
  {
    "id": "autocad",
    "name": "AutoCAD LT",
    "package": "",
    "packageManager": "powershell",
    "customScript": "app/autocad_install/install.ps1",
    "disabled": true
  },
  {
    "id": "kdenlive",
    "name": "Kdenlive",
    "package": "KDE.Kdenlive",
    "packageManager": "winget"
  },
  {
    "id": "krita",
    "name": "Krita",
    "package": "KDE.Krita",
    "packageManager": "winget"
  },
  {
    "id": "gimp",
    "name": "GIMP",
    "package": "GIMP.GIMP",
    "packageManager": "winget"
  },
  {
    "id": "blender",
    "name": "Blender",
    "package": "BlenderFoundation.Blender",
    "packageManager": "winget"
  },
  {
    "id": "freecad",
    "name": "FreeCAD",
    "package": "FreeCAD.FreeCAD",
    "packageManager": "winget"
  },
  {
    "id": "netfx35",
    "name": ".NET Framework 3.5",
    "package": "",
    "packageManager": "powershell",
    "customScript": "app/netfx35_install/install.ps1"
  },
  {
    "id": "vstor",
    "name": "VS Tools for Office 2010",
    "package": "Microsoft.VSTOR",
    "packageManager": "winget"
  },
  {
    "id": "bnsc",
    "name": "Du toan BNSC",
    "package": "",
    "packageManager": "powershell",
    "customScript": "app/bnsc_install/install.ps1",
    "dependencies": [
      "netfx35",
      "vstor",
      "office"
    ]
  },
  {
    "id": "lockxls",
    "name": "LockXLS",
    "package": "",
    "packageManager": "powershell",
    "customScript": "app/lockxls_install/install.ps1",
    "dependencies": [
      "bnsc"
    ]
  }
]
'@
$script:Embedded_PrintersJson = @'
[
  {
    "id": "brother_t4500",
    "name": "Brother T4500DW DN",
    "url": "192.168.3.20",
    "portType": "tcpip",
    "port": "IP_192.168.3.20",
    "driver": "Brother MFC-T4500DW Printer",
    "driverUrl": "https://download.brother.com/welcome/dlf103803/Y17F_C1-hostm-H1.EXE",
    "driverInstallArgs": ["/S", "/norestart"]
  },
  {
    "id": "hp4003_dn",
    "name": "HP 4003 DN",
    "url": "192.168.3.21",
    "paperSize": "A4"
  },
  {
    "id": "ricoh_mp3555_dn",
    "name": "Ricoh MP 3555 DN (Photocopy)",
    "url": "192.168.3.23",
    "ippPath": "/printer",
    "paperSize": "A4"
  },
  {
    "id": "epson_l1800_dn",
    "name": "EPSON L1800 DN",
    "url": "192.168.3.24",
    "portType": "lpr",
    "port": "EPSON_L1800_DN_LPR",
    "lprQueue": "L1800",
    "driver": "EPSON L1800 Series",
    "driverUrl": "https://download3.ebz.epson.net/dsc/f/03/00/13/77/76/a8a9b4031a90f77fc81f66ca944fc8751e3bfd47/L1800_x64_21201UsHomeExportAsiaML.exe",
    "driverInstallArgs": ["/s"]
  },
  {
    "id": "hp404_dn_ngoai",
    "name": "HP 404dn DN (ben ngoai)",
    "url": "192.168.3.26",
    "paperSize": "A4"
  },
  {
    "id": "hp404_dn_trong",
    "name": "HP 404dn DN (ben trong)",
    "url": "192.168.3.27",
    "paperSize": "A4"
  },
  {
    "id": "brother_t4500_kd",
    "name": "Brother T4500DW Kinh Doanh",
    "url": "192.168.4.12",
    "portType": "tcpip",
    "port": "IP_192.168.4.12",
    "driver": "Brother MFC-T4500DW Printer",
    "driverUrl": "https://download.brother.com/welcome/dlf103803/Y17F_C1-hostm-H1.EXE",
    "driverInstallArgs": ["/S", "/norestart"]
  },
  {
    "id": "brother_t4500_dd",
    "name": "Brother T4500 Dat Dai",
    "url": "192.168.4.13",
    "portType": "tcpip",
    "port": "IP_192.168.4.13",
    "driver": "Brother MFC-T4500DW Printer",
    "driverUrl": "https://download.brother.com/welcome/dlf103803/Y17F_C1-hostm-H1.EXE",
    "driverInstallArgs": ["/S", "/norestart"]
  },
  {
    "id": "hp402dn_ns",
    "name": "HP 402dn HCNS",
    "url": "192.168.4.20",
    "paperSize": "A4"
  },
  {
    "id": "brother_t4500_hcns",
    "name": "Brother T4500DW HCNS",
    "url": "192.168.4.22",
    "portType": "tcpip",
    "port": "IP_192.168.4.22",
    "driver": "Brother MFC-T4500DW Printer",
    "driverUrl": "https://download.brother.com/welcome/dlf103803/Y17F_C1-hostm-H1.EXE",
    "driverInstallArgs": ["/S", "/norestart"]
  },
  {
    "id": "hp402dn_dd",
    "name": "HP 402dn Dat dai",
    "url": "192.168.4.24",
    "paperSize": "A4"
  },
  {
    "id": "epson_l1800_da",
    "name": "EPSON L1800 Du An",
    "url": "192.168.4.25",
    "portType": "lpr",
    "port": "EPSON_L1800_CD_LPR",
    "lprQueue": "L1800",
    "driver": "EPSON L1800 Series",
    "driverUrl": "https://download3.ebz.epson.net/dsc/f/03/00/13/77/76/a8a9b4031a90f77fc81f66ca944fc8751e3bfd47/L1800_x64_21201UsHomeExportAsiaML.exe",
    "driverInstallArgs": ["/s"]
  },
  {
    "id": "hp402dn_khth",
    "name": "HP 402dn KHTH CD",
    "url": "192.168.4.27",
    "paperSize": "A4"
  },
  {
    "id": "hp401_gs",
    "name": "HP 401 Giam sat",
    "url": "192.168.4.28",
    "paperSize": "A4"
  },
  {
    "id": "hp402dn_tckt",
    "name": "HP 402dn TCKT",
    "url": "192.168.4.29",
    "paperSize": "A4"
  },
  {
    "id": "hp402dn_tckt",
    "name": "HP 402dn TCKT",
    "url": "192.168.4.29",
    "paperSize": "A4"
  },
  {
    "id": "hp402dn_kd",
    "name": "HP 402dn Kinh Doanh",
    "url": "192.168.4.30",
    "paperSize": "A4"
  },
  {
    "id": "hp402dn_da",
    "name": "HP 406dn Du An",
    "url": "192.168.4.34",
    "paperSize": "A4"
  },
  {
    "id": "ricoh_mp2555_cd",
    "name": "Ricoh MP 2555 CD (Photocopy)",
    "url": "192.168.4.38",
    "ippPath": "/printer",
    "paperSize": "A4"
  }
]
'@
$script:Embedded_DepartmentsJson = @'
[
  {
    "id": "directors",
    "name": "Ban Giam Doc (Directors)",
    "apps": [
      "office",
      "viber",
      "zalo",
      "chrome",
      "onedrive",
      "unikey",
      "7zip",
      "kes"
    ],
    "printers": [
      "hp4003",
      "ricoh_mp3555"
    ]
  },
  {
    "id": "accounting",
    "name": "Ke Toan (Accounting)",
    "apps": [
      "office",
      "viber",
      "zalo",
      "chrome",
      "onedrive",
      "unikey",
      "7zip",
      "kes",
      "vcredist_x64",
      "vcredist_x86"
    ],
    "printers": [
      "brother_t4500",
      "ricoh_mp3555"
    ]
  },
  {
    "id": "hr_admin",
    "name": "Hanh Chinh Nhan Su (HR & Admin)",
    "apps": [
      "office",
      "viber",
      "zalo",
      "chrome",
      "onedrive",
      "unikey",
      "7zip",
      "kes",
      "ultraviewer"
    ],
    "printers": [
      "epson_l1800",
      "ricoh_mp3555"
    ]
  },
  {
    "id": "sales",
    "name": "Kinh Doanh (Sales / Marketing)",
    "apps": [
      "office",
      "viber",
      "zalo",
      "chrome",
      "onedrive",
      "unikey",
      "7zip",
      "kes"
    ],
    "printers": [
      "ricoh_mp3555"
    ]
  },
  {
    "id": "it_tech",
    "name": "Ky Thuat (IT / Tech)",
    "apps": [
      "unikey",
      "viber",
      "zalo",
      "office",
      "7zip",
      "kes",
      "onedrive",
      "ultraviewer",
      "chrome",
      "vcredist_x64",
      "vcredist_x86"
    ],
    "printers": [
      "hp4003",
      "brother_t4500",
      "ricoh_mp3555",
      "epson_l1800"
    ]
  }
]
'@
$script:Embedded_OfficeCustomXml = @'
<Configuration>
  <Add>
    <Product ID="O365BusinessRetail">
      <Language ID="en-us"/>
      <Language ID="vi-vn"/>
      <ExcludeApp ID="Teams"/>
    </Product>
  </Add>
  <RemoveMSI/>
  <Display Level="Full" AcceptEULA="TRUE"/>
  <Property Name="FORCEAPPSHUTDOWN" Value="TRUE"/>
</Configuration>
'@

# --- DOWNLOAD HELPER ---
# Helper script for high-speed multi-connection file downloads with real-time progress monitoring

function Start-MultiDownload
{
  [CmdletBinding()]
  param(
    [Parameter(Mandatory = $true)][string]$Url,
    [Parameter(Mandatory = $true)][string]$OutFile,
    [int]$Connections = 8,
    [string]$ActivityName = "Downloading File"
  )

  # Ensure .NET allows parallel connections to the same host
  [System.Net.ServicePointManager]::DefaultConnectionLimit = 100
  try
  {
    [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12 -bor [System.Net.SecurityProtocolType]::Tls13
  } catch {}

  # Ensure destination directory exists
  $outDir = Split-Path $OutFile -Parent
  if ($outDir -and -not (Test-Path $outDir))
  {
    New-Item -ItemType Directory -Force -Path $outDir | Out-Null
  }

  # Remove existing target file if present
  if (Test-Path $OutFile)
  {
    Remove-Item $OutFile -Force -ErrorAction SilentlyContinue
  }

  Write-Host "Preparing download for: $(Split-Path $OutFile -Leaf)" -ForegroundColor Cyan

  # --- Step 1: Check server support via HEAD request ---
  $headReq = [System.Net.HttpWebRequest]::Create($Url)
  $headReq.Method = "HEAD"
  $headReq.Timeout = 20000
  $headReq.ServicePoint.ConnectionLimit = 100
  $fileSize = -1
  $acceptRanges = ""

  try
  {
    $headResp = $headReq.GetResponse()
    $fileSize = $headResp.ContentLength
    $acceptRanges = $headResp.Headers["Accept-Ranges"]
    $headResp.Close()
  }
  catch
  {
    Write-Host "  Server HEAD check failed. Defaulting to single-connection download..." -ForegroundColor Yellow
  }

  # Helper for single-connection fallbacks
  $doSingleDownload = {
    Write-Host "  Using BITS Transfer..." -ForegroundColor Yellow
    try
    {
      Start-BitsTransfer -Source $Url -Destination $OutFile -ErrorAction Stop
      Write-Host "  Download completed via BITS Transfer." -ForegroundColor Green
      return
    }
    catch
    {
      Write-Host "  BITS Transfer failed: $($_.Exception.Message). Trying WebClient..." -ForegroundColor Yellow
      if (Test-Path $OutFile) { Remove-Item $OutFile -Force -ErrorAction SilentlyContinue }

      $wc = New-Object System.Net.WebClient
      try
      {
        $wc.DownloadFile($Url, $OutFile)
        Write-Host "  Download completed via WebClient." -ForegroundColor Green
        return
      }
      catch
      {
        throw "All download methods failed. Error: $($_.Exception.Message)"
      }
      finally
      {
        if ($wc) { $wc.Dispose() }
      }
    }
  }

  # Fallback to single-connection download if Range header is unsupported or size unknown
  if ($fileSize -le 0 -or $acceptRanges -ne "bytes")
  {
    Write-Host "  Multi-connection not supported by server." -ForegroundColor Yellow
    & $doSingleDownload
    return
  }

  $totalMB = [math]::Round($fileSize / 1MB, 2)
  Write-Host "  File size: $totalMB MB | Parallel Connections: $Connections" -ForegroundColor Cyan

  # --- Step 2: Calculate chunk byte ranges ---
  $chunkSize = [math]::Ceiling($fileSize / $Connections)
  $chunks = @()
  for ($i = 0; $i -lt $Connections; $i++)
  {
    $start = [long]($i * $chunkSize)
    $end   = [math]::Min([long](($i + 1) * $chunkSize - 1), [long]($fileSize - 1))
    $partFile = "$OutFile.part$i"
    if (Test-Path $partFile) { Remove-Item $partFile -Force -ErrorAction SilentlyContinue }
    $chunks += @{ Index = $i; Start = $start; End = $end; File = $partFile }
  }

  # --- Step 3: Define worker script block ---
  $workerBlock = {
    param([string]$chunkUrl, [long]$rangeStart, [long]$rangeEnd, [string]$partFile)
    [System.Net.ServicePointManager]::DefaultConnectionLimit = 100
    $req = [System.Net.HttpWebRequest]::Create($chunkUrl)
    $req.ServicePoint.ConnectionLimit = 100
    $req.AddRange([long]$rangeStart, [long]$rangeEnd)
    $req.Timeout = 180000  # 3 minute timeout per chunk connection
    $resp = $req.GetResponse()
    $stream = $resp.GetResponseStream()
    $fs = [System.IO.File]::Create($partFile)
    try
    {
      $buffer = New-Object byte[] 65536  # 64KB buffer
      while (($bytesRead = $stream.Read($buffer, 0, $buffer.Length)) -gt 0)
      {
        $fs.Write($buffer, 0, $bytesRead)
      }
    }
    finally
    {
      $fs.Close()
      $stream.Close()
      $resp.Close()
    }
  }

  # --- Step 4: Launch parallel runspaces ---
  try
  {
    $pool = [runspacefactory]::CreateRunspacePool(1, $Connections)
    $pool.Open()

    $handles = @()
    foreach ($chunk in $chunks)
    {
      $ps = [powershell]::Create()
      $ps.RunspacePool = $pool
      $ps.AddScript($workerBlock) | Out-Null
      $ps.AddArgument($Url) | Out-Null
      $ps.AddArgument($chunk.Start) | Out-Null
      $ps.AddArgument($chunk.End) | Out-Null
      $ps.AddArgument($chunk.File) | Out-Null
      $async = $ps.BeginInvoke()
      $handles += @{ PS = $ps; Async = $async; Chunk = $chunk }
    }

    # --- Step 5: Monitor progress in real-time ---
    $startTime = [DateTime]::Now
    $lastTime  = $startTime
    $lastBytes = 0

    while ($true)
    {
      $pending = $handles | Where-Object { -not $_.Async.IsCompleted }

      # Calculate downloaded bytes across all part files
      $downloadedBytes = 0
      $activeParts = 0
      foreach ($chunk in $chunks)
      {
        if (Test-Path $chunk.File)
        {
          $len = (Get-Item $chunk.File -ErrorAction SilentlyContinue).Length
          $downloadedBytes += $len
          if ($len -gt 0) { $activeParts++ }
        }
      }

      if ($downloadedBytes -gt $fileSize) { $downloadedBytes = $fileSize }
      $percent = [math]::Min(100.0, [math]::Round(($downloadedBytes / $fileSize) * 100, 1))

      # Calculate current speed
      $now = [DateTime]::Now
      $timeDiff = ($now - $lastTime).TotalSeconds
      $speedMBps = 0.0
      if ($timeDiff -ge 0.5)
      {
        $bytesDiff = $downloadedBytes - $lastBytes
        $speedMBps = [math]::Round(($bytesDiff / $timeDiff) / 1MB, 2)
        $lastTime  = $now
        $lastBytes = $downloadedBytes
      }

      $downloadedMB = [math]::Round($downloadedBytes / 1MB, 1)
      $statusText   = "$downloadedMB MB / $totalMB MB ($percent%) | Speed: $speedMBps MB/s | Parts active: $activeParts/$Connections"

      Write-Progress -Activity $ActivityName -Status $statusText -PercentComplete ([int]$percent)

      if ($pending.Count -eq 0) { break }
      Start-Sleep -Milliseconds 300
    }

    Write-Progress -Activity $ActivityName -Status "Download complete ($totalMB MB)" -Completed

    # --- Step 6: Collect errors ---
    $errors = @()
    foreach ($h in $handles)
    {
      try
      {
        $h.PS.EndInvoke($h.Async)
      }
      catch
      {
        $errors += "Part $($h.Chunk.Index): $($_.Exception.Message)"
      }
      $h.PS.Dispose()
    }
    $pool.Close()
    $pool.Dispose()

    if ($errors.Count -gt 0)
    {
      throw "Parallel download incomplete: $($errors -join '; ')"
    }

    # --- Step 7: Merge chunk files into target ---
    Write-Host "  Merging $Connections parts into destination file..." -ForegroundColor Cyan
    $outStream = [System.IO.File]::Create($OutFile)
    try
    {
      foreach ($chunk in ($chunks | Sort-Object { $_.Index }))
      {
        $partStream = [System.IO.File]::OpenRead($chunk.File)
        try
        {
          $partStream.CopyTo($outStream)
        }
        finally
        {
          $partStream.Close()
        }
      }
    }
    finally
    {
      $outStream.Close()
    }

    # Clean up part files
    foreach ($chunk in $chunks)
    {
      Remove-Item $chunk.File -Force -ErrorAction SilentlyContinue
    }

    $finalSize = (Get-Item $OutFile).Length
    $finalMB   = [math]::Round($finalSize / 1MB, 2)
    $totalTime = [math]::Round(([DateTime]::Now - $startTime).TotalSeconds, 1)

    # Validate final file size matches expected size
    if ($fileSize -gt 0 -and $finalSize -lt ($fileSize - 1000))
    {
      throw "Downloaded file size mismatch: Expected $fileSize bytes, got $finalSize bytes."
    }

    Write-Host "  Download complete: $finalMB MB in $totalTime seconds." -ForegroundColor Green
  }
  catch
  {
    Write-Host "  Multi-connection download failed: $($_.Exception.Message)" -ForegroundColor Yellow
    Write-Host "  Cleaning up temporary parts and switching to single-connection..." -ForegroundColor Yellow

    foreach ($chunk in $chunks)
    {
      if (Test-Path $chunk.File) { Remove-Item $chunk.File -Force -ErrorAction SilentlyContinue }
    }
    if (Test-Path $OutFile) { Remove-Item $OutFile -Force -ErrorAction SilentlyContinue }

    & $doSingleDownload
  }
}

function Start-GoogleDriveDownload
{
  [CmdletBinding()]
  param(
    [Parameter(Mandatory = $true)][string]$UrlOrId,
    [Parameter(Mandatory = $true)][string]$OutFile
  )

  # Extract File ID from link formats like:
  # https://drive.google.com/file/d/FILE_ID/view
  # https://drive.google.com/open?id=FILE_ID
  # https://drive.google.com/uc?export=download&id=FILE_ID
  # or raw FILE_ID
  $fileId = $UrlOrId.Trim()
  if ($UrlOrId -match "id=([a-zA-Z0-9_-]+)")
  {
    $fileId = $Matches[1]
  }
  elseif ($UrlOrId -match "/d/([a-zA-Z0-9_-]+)")
  {
    $fileId = $Matches[1]
  }

  Write-Host "Downloading file from Google Drive (ID: $fileId)..." -ForegroundColor Cyan

  $outDir = Split-Path $OutFile -Parent
  if ($outDir -and -not (Test-Path $outDir))
  {
    New-Item -ItemType Directory -Force -Path $outDir | Out-Null
  }

  if (Test-Path $OutFile)
  {
    Remove-Item $OutFile -Force -ErrorAction SilentlyContinue
  }

  $ProgressPreference = 'SilentlyContinue'

  # Method A: Try curl.exe if available
  if (Get-Command "curl.exe" -ErrorAction SilentlyContinue)
  {
    $cookieFile = [System.IO.Path]::GetTempFileName()
    try
    {
      $ucUrl = "https://docs.google.com/uc?export=download&id=$fileId"
      # Step 1: Initial request to get cookie and confirm form
      $html = & curl.exe -s -L -c $cookieFile "$ucUrl"

      $uuid = $null
      $actionUrl = "https://drive.usercontent.google.com/download"

      if ($html -match 'action="([^"]+)".*?name="uuid" value="([^"]+)"')
      {
        $actionUrl = $Matches[1]
        $uuid = $Matches[2]
      }
      elseif ($html -match 'name="uuid" value="([^"]+)"')
      {
        $uuid = $Matches[1]
      }

      $confirmToken = $null
      if ($html -match 'confirm=([0-9a-zA-Z_]+)')
      {
        $confirmToken = $Matches[1]
      }
      elseif ($html -match 'name="confirm" value="([^"]+)"')
      {
        $confirmToken = $Matches[1]
      }

      if ($uuid)
      {
        $confirmUrl = "${actionUrl}?id=${fileId}&export=download&confirm=t&uuid=${uuid}"
        & curl.exe -L -b $cookieFile -o $OutFile "$confirmUrl"
      }
      elseif ($confirmToken)
      {
        $confirmUrl = "https://docs.google.com/uc?export=download&confirm=$confirmToken&id=$fileId"
        & curl.exe -L -b $cookieFile -o $OutFile "$confirmUrl"
      }
      else
      {
        # Fallback to direct download
        $confirmUrl = "https://docs.google.com/uc?export=download&confirm=t&id=$fileId"
        & curl.exe -L -b $cookieFile -o $OutFile "$confirmUrl"
      }
    }
    finally
    {
      if (Test-Path $cookieFile) { Remove-Item $cookieFile -Force -ErrorAction SilentlyContinue }
    }
  }
  else
  {
    # Method B: Pure PowerShell WebRequest with WebRequestSession
    $session = New-Object Microsoft.PowerShell.Commands.WebRequestSession
    $ucUrl = "https://docs.google.com/uc?export=download&id=$fileId"
    $resp = Invoke-WebRequest -Uri $ucUrl -WebSession $session -UseBasicParsing

    if ($resp.Headers["Content-Type"] -notlike "*text/html*")
    {
      [System.IO.File]::WriteAllBytes($OutFile, $resp.Content)
    }
    else
    {
      $uuid = $null
      $actionUrl = "https://drive.usercontent.google.com/download"
      if ($resp.Content -match 'action="([^"]+)".*?name="uuid" value="([^"]+)"')
      {
        $actionUrl = $Matches[1]
        $uuid = $Matches[2]
      }
      elseif ($resp.Content -match 'name="uuid" value="([^"]+)"')
      {
        $uuid = $Matches[1]
      }

      $confirmToken = $null
      if ($resp.Content -match 'confirm=([0-9a-zA-Z_]+)') { $confirmToken = $Matches[1] }
      elseif ($resp.Content -match 'name="confirm" value="([^"]+)"') { $confirmToken = $Matches[1] }

      $confirmUrl = if ($uuid) {
        "${actionUrl}?id=${fileId}&export=download&confirm=t&uuid=${uuid}"
      } elseif ($confirmToken) {
        "https://docs.google.com/uc?export=download&confirm=$confirmToken&id=$fileId"
      } else {
        "https://docs.google.com/uc?export=download&confirm=t&id=$fileId"
      }

      Invoke-WebRequest -Uri $confirmUrl -OutFile $OutFile -WebSession $session -UseBasicParsing
    }
  }

  # Validate downloaded file
  if (-not (Test-Path $OutFile) -or (Get-Item $OutFile).Length -lt 10000)
  {
    $sample = Get-Content $OutFile -Raw -ErrorAction SilentlyContinue
    if ($sample -like "*<html*" -or $sample -like "*Google Drive*")
    {
      Remove-Item $OutFile -Force -ErrorAction SilentlyContinue
      throw "Google Drive download failed. The file is either restricted (requires sign-in / 'Anyone with the link' sharing) or the ID is invalid."
    }
  }

  Write-Host "Google Drive download successful." -ForegroundColor Green
}



# --- PRINTER INSTALLER ---
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
                try {
                    Add-PrinterPort -Name $Port -LprHostAddress $Url -LprQueueName $LprQueue -LprByteCounting -ErrorAction Stop
                } catch {
                    Write-Host "  LPR port creation unavailable ($($_.Exception.Message)). Falling back to Standard TCP/IP port..." -ForegroundColor Yellow
                    Add-PrinterPort -Name $Port -PrinterHostAddress $Url -ErrorAction Stop
                }
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


# --- EMBEDDED CUSTOM INSTALLERS ---
$script:EmbeddedCustomScripts = @{
  "app/office_install/install.ps1" = {
    $OdtDir = "C:\ProgramData\SZC\InstallCache\odt"
    New-Item -ItemType Directory -Force -Path $OdtDir | Out-Null
    Set-Content -Path (Join-Path $OdtDir "OfficeCustom.xml") -Value $script:Embedded_OfficeCustomXml -Encoding UTF8 -Force
    $OfficeXMLSrc = Join-Path $OdtDir "OfficeCustom.xml"
# Use $MyInvocation to find this script's own directory -- works correctly even when dot-sourced
# ($PSScriptRoot resolves to the CALLER's directory when dot-sourced, so never use it here)
$_thisDir     = Split-Path $MyInvocation.MyCommand.Path -Parent
$OfficeXMLSrc = Join-Path $_thisDir "OfficeCustom.xml"

$CacheDir = "C:\ProgramData\SZC\InstallCache"
$OdtDir   = Join-Path $CacheDir "odt"

# Ensure directories exist
New-Item -ItemType Directory -Force -Path $CacheDir | Out-Null
New-Item -ItemType Directory -Force -Path $OdtDir   | Out-Null

# Copy XML into $OdtDir so setup.exe and OfficeCustom.xml are in the same folder.
# Running setup.exe from the same directory as the XML (with just the filename, no path)
# is the most reliable way to avoid error 0-2048 "couldn't find configuration file".
$OfficeXML = Join-Path $OdtDir "OfficeCustom.xml"
Copy-Item -Path $OfficeXMLSrc -Destination $OfficeXML -Force

# --- Step 1: Obtain ODT setup.exe ---
# The fwlink URL (LinkID=626065) redirects to the Microsoft Download Center *web page*,
# NOT a direct binary. Both Invoke-WebRequest and WebClient download the HTML page.
#
# Solution: Download setup.exe directly from the Office CDN, which is a stable, direct
# binary URL that does not involve any redirects or HTML pages.
$SetupExe = Join-Path $OdtDir "setup.exe"
$CdnUrl   = "https://officecdn.microsoft.com/pr/wsus/setup.exe"

# Remove any leftover partial/corrupt download from a previous attempt
if (Test-Path $SetupExe) { Remove-Item $SetupExe -Force }

# --- Download helper: try multiple methods for maximum reliability ---
function Download-SetupExe
{
  param([string]$Url, [string]$OutFile)

  # --- Method 1: curl.exe (ships with Windows 10 1803+ / Windows 11) ---
  # curl.exe handles redirects natively with -L and is the most reliable option.
  $curlPath = Get-Command curl.exe -ErrorAction SilentlyContinue
  if ($curlPath)
  {
    Write-Output "Downloading setup.exe (Method 1: curl.exe)..."
    try
    {
      $curlProc = Start-Process -FilePath "curl.exe" `
        -ArgumentList "-L", "-o", "`"$OutFile`"", "--retry", "3", "--retry-delay", "5", "-s", "-S", "`"$Url`"" `
        -NoNewWindow -PassThru -Wait

      if ($curlProc.ExitCode -eq 0 -and (Test-Path $OutFile))
      {
        Write-Output "curl.exe download completed."
        return
      }
      Write-Output "curl.exe failed (exit code $($curlProc.ExitCode)), falling back..."
    }
    catch
    {
      Write-Output "curl.exe failed: $($_.Exception.Message). Falling back..."
    }
    if (Test-Path $OutFile) { Remove-Item $OutFile -Force }
  }

  # --- Method 2: Invoke-WebRequest (with ProgressPreference disabled) ---
  Write-Output "Downloading setup.exe (Method 2: Invoke-WebRequest)..."
  try
  {
    $oldProgress = $ProgressPreference
    $ProgressPreference = 'SilentlyContinue'
    try
    {
      Invoke-WebRequest -Uri $Url -OutFile $OutFile -UseBasicParsing -MaximumRedirection 10
    }
    finally
    {
      $ProgressPreference = $oldProgress
    }

    if (Test-Path $OutFile)
    {
      Write-Output "Invoke-WebRequest download completed."
      return
    }
    Write-Output "Invoke-WebRequest produced no file, falling back..."
  }
  catch
  {
    Write-Output "Invoke-WebRequest failed: $($_.Exception.Message). Falling back..."
  }
  if (Test-Path $OutFile) { Remove-Item $OutFile -Force }

  # --- Method 3: System.Net.WebClient ---
  Write-Output "Downloading setup.exe (Method 3: System.Net.WebClient)..."
  try
  {
    $wc = New-Object System.Net.WebClient
    $wc.DownloadFile($Url, $OutFile)
  }
  catch
  {
    throw "All download methods failed. Last error: $($_.Exception.Message)"
  }
  finally
  {
    if ($wc) { $wc.Dispose() }
  }
}

Download-SetupExe -Url $CdnUrl -OutFile $SetupExe

# --- Validate the downloaded setup.exe ---
if (-not (Test-Path $SetupExe))
{
  throw "setup.exe not found after download."
}

$setupSize = (Get-Item $SetupExe).Length
Write-Output "setup.exe downloaded: $setupSize bytes"

# Only reject if the file is suspiciously tiny (under 10KB = likely an HTML error page).
# The real setup.exe from the Office CDN can be small since it is a bootstrapper.
if ($setupSize -lt 10KB)
{
  # Check if the file looks like HTML (redirect/error page) rather than a binary
  $head = Get-Content $SetupExe -TotalCount 5 -ErrorAction SilentlyContinue
  $headText = ($head -join "`n").ToLower()
  if ($headText -match '<html|<head|<!doctype|window\.location')
  {
    Remove-Item $SetupExe -Force -ErrorAction SilentlyContinue
    throw "Download returned an HTML page instead of setup.exe. Check network/proxy settings. File was $setupSize bytes."
  }
  Remove-Item $SetupExe -Force -ErrorAction SilentlyContinue
  throw "setup.exe too small ($setupSize bytes). Download may be truncated or corrupted. Check network connectivity."
}

# --- Step 2: Run setup.exe /configure (fully silent, no UI) ---
# Use -WorkingDirectory $OdtDir and pass just the bare filename "OfficeCustom.xml".
# This avoids error 0-2048 because setup.exe looks for the XML relative to its
# working directory, so no path/quoting ambiguity is possible.
Write-Output "Starting Office 365 deployment..."
$Proc = Start-Process `
  -FilePath $SetupExe `
  -ArgumentList "/configure OfficeCustom.xml" `
  -WorkingDirectory $OdtDir `
  -NoNewWindow `
  -PassThru `
  -Wait

$exitCode = $Proc.ExitCode
Write-Output "Office setup exited with code: $exitCode"

# --- Step 3: Cleanup on success ---
if ($exitCode -eq 0)
{
  Write-Output "Office 365 installed successfully."
} else
{
  Write-Output "ODT files left at: $OdtDir (for retry/debugging)"
  throw "Office setup failed with exit code $exitCode. Check ODT logs in %TEMP% for details."
}

  }
  "app/kes_install/install.ps1" = {
$Url      = "https://aes.s.kaspersky-labs.com/endpoints/keswin11/14.0.0.504/vietnamese-INT-21.25.7.504.0.143.0/a0b3932eaa6c05bcb1ae932d500116a2/keswin_14.0.0.504_vi_aes56.exe"
$CacheDir = "C:\ProgramData\SZC\InstallCache"
$KesDir   = Join-Path $CacheDir "kes_extracted"

# Ensure directories exist
New-Item -ItemType Directory -Force -Path $CacheDir | Out-Null
New-Item -ItemType Directory -Force -Path $KesDir   | Out-Null

$DownloadedExe = Join-Path $CacheDir "keswin_setup.exe"
$ArchiveAs7z   = Join-Path $CacheDir "keswin_setup.7z"

# --- Step 1: Ensure download helper is loaded and download installer ---
if (-not (Get-Command Start-MultiDownload -ErrorAction SilentlyContinue))
{
  $_thisDir = Split-Path $MyInvocation.MyCommand.Path -Parent
  $_helperPath = Join-Path $_thisDir "..\download_helper.ps1"
  if (Test-Path $_helperPath)
  { . $_helperPath 
  }
}

# Remove leftover download if present
if (Test-Path $DownloadedExe)
{ Remove-Item $DownloadedExe -Force -ErrorAction SilentlyContinue 
}

Write-Host "Downloading Kaspersky Endpoint Security..."
Start-MultiDownload -Url $Url -OutFile $DownloadedExe -Connections 8 -ActivityName "Downloading Kaspersky Endpoint Security"

if (-not (Test-Path $DownloadedExe))
{
  throw "Kaspersky installer file missing after download."
}

# --- Step 2: Rename .exe -> .7z so 7-Zip can extract it ---
Copy-Item -Path $DownloadedExe -Destination $ArchiveAs7z -Force

# --- Step 3: Locate 7-Zip executable ---
$7zPaths = @(
  "C:\Program Files\7-Zip\7z.exe",
  "C:\Program Files (x86)\7-Zip\7z.exe"
)
$7zExe = $7zPaths | Where-Object { Test-Path $_ } | Select-Object -First 1

if (-not $7zExe)
{
  throw "7-Zip is not installed. Please install 7-Zip before deploying Kaspersky Endpoint Security."
}

# --- Step 4: Extract the archive ---
Write-Host "Extracting KES package with 7-Zip..."
$extractProc = Start-Process `
  -FilePath $7zExe `
  -ArgumentList @("x", "`"$ArchiveAs7z`"", "-o`"$KesDir`"", "-y") `
  -NoNewWindow `
  -PassThru `
  -Wait

if ($extractProc.ExitCode -ne 0)
{
  throw "7-Zip extraction failed with exit code $($extractProc.ExitCode)."
}

# --- Step 5: Find installer inside the extracted folder (prioritize MSI) ---
$realInstaller = Get-ChildItem -Path $KesDir -Filter "*.msi" -Recurse -ErrorAction SilentlyContinue |
  Select-Object -First 1

if (-not $realInstaller)
{
  # Fallback 1: setup.exe executable
  $realInstaller = Get-ChildItem -Path $KesDir -Filter "*setup*.exe" -Recurse -ErrorAction SilentlyContinue |
    Select-Object -First 1
}

if (-not $realInstaller)
{
  # Fallback 2: any .exe in extracted folder
  $realInstaller = Get-ChildItem -Path $KesDir -Filter "*.exe" -Recurse -ErrorAction SilentlyContinue |
    Select-Object -First 1
}

if (-not $realInstaller)
{
  throw "Could not find a setup executable or MSI package inside the extracted KES package at: $KesDir"
}

Write-Host "Found installer: $($realInstaller.FullName)"

# --- Step 6: Run installer ---
if ($realInstaller.Extension -eq ".msi")
{
  Write-Host "Running Kaspersky MSI installation (unattended, progress bar only)..."
  $installProc = Start-Process `
    -FilePath "msiexec.exe" `
    -ArgumentList @("/i", "`"$($realInstaller.FullName)`"", "/passive", "EULA=1", "PRIVACYPOLICY=1", "KSN=0") `
    -NoNewWindow `
    -PassThru `
    -Wait
} else
{
  Write-Host "Running Kaspersky EXE installation (unattended, progress bar parameters)..."
  $installProc = Start-Process `
    -FilePath $realInstaller.FullName `
    -ArgumentList @("/s", "/pEULA=1", "/pPRIVACYPOLICY=1", "/pKSN=0", "/v`"/passive EULA=1 PRIVACYPOLICY=1 KSN=0`"") `
    -NoNewWindow `
    -PassThru `
    -Wait
}

$exitCode = $installProc.ExitCode
Write-Host "KES installer exited with code: $exitCode"

# --- Step 7: Cleanup (only on success) ---
if ($exitCode -eq 0)
{
  Remove-Item $DownloadedExe -Force -ErrorAction SilentlyContinue
  Remove-Item $ArchiveAs7z   -Force -ErrorAction SilentlyContinue
  Remove-Item $KesDir        -Recurse -Force -ErrorAction SilentlyContinue
  Write-Host "Kaspersky Endpoint Security installed successfully."
} else
{
  Write-Host "Files left in: $CacheDir and $KesDir (for retry/debugging)"
  throw "KES installation failed with exit code $exitCode."
}

  }
  "app/bnsc_install/install.ps1" = {
# Du toan BNSC Installer
# Downloads from Google Drive and installs silently.
# Dependencies: .NET Framework 3.5, VS Tools for Office 2010, Microsoft Office

$CacheDir    = "C:\ProgramData\SZC\InstallCache\bnsc"
$DownloadUrl = "https://drive.google.com/file/d/15PJp17mN5XNhYf-H8yDoBeFUURu2VMmG/view?pli=1"
$InstallerName = "Cai_dat_du_toan_BNSC.exe"
$InstallerPath = Join-Path $CacheDir $InstallerName

if ([string]::IsNullOrWhiteSpace($DownloadUrl)) {
    throw "BNSC download URL is not configured. Update the `$DownloadUrl variable in bnsc_install/install.ps1"
}

# --- Helper functions to temporarily bypass Antivirus (Defender / KES) ---
function Disable-AntivirusProtection {
    Write-Host "Temporarily adjusting Antivirus settings for BNSC installation..." -ForegroundColor Yellow

    # 1. Windows Defender Exclusions & Real-time pause
    try {
        if (Get-Command "Add-MpPreference" -ErrorAction SilentlyContinue) {
            Add-MpPreference -ExclusionPath $CacheDir -ErrorAction SilentlyContinue
            Add-MpPreference -ExclusionPath "C:\Program Files (x86)\BNSC" -ErrorAction SilentlyContinue
            Add-MpPreference -ExclusionPath "C:\Program Files\BNSC" -ErrorAction SilentlyContinue
            Add-MpPreference -ExclusionPath "C:\ProgramData\SZC" -ErrorAction SilentlyContinue
            Add-MpPreference -ExclusionPath "C:\SecureDongle.dll" -ErrorAction SilentlyContinue
            Add-MpPreference -ExclusionProcess $InstallerName -ErrorAction SilentlyContinue
            Set-MpPreference -DisableRealtimeMonitoring $true -ErrorAction SilentlyContinue
            Write-Host "  Windows Defender real-time monitoring paused & BNSC exclusions added." -ForegroundColor Green
        }
    } catch {
        Write-Host "  (Notice: Windows Defender preference modification skipped)" -ForegroundColor DarkGray
    }

    # 2. Kaspersky Endpoint Security (KES) - Pause via avp.com CLI if installed
    $kesPaths = @(
        "$env:ProgramFiles (x86)\Kaspersky Lab\Kaspersky Endpoint Security for Windows\avp.com",
        "$env:ProgramFiles\Kaspersky Lab\Kaspersky Endpoint Security for Windows\avp.com"
    )
    foreach ($avp in $kesPaths) {
        if (Test-Path $avp) {
            try {
                Write-Host "  Found Kaspersky Endpoint Security, pausing protection..." -ForegroundColor Yellow
                Start-Process -FilePath $avp -ArgumentList "STOP" -NoNewWindow -Wait -ErrorAction SilentlyContinue
            } catch {
                Write-Host "  (Notice: Could not pause Kaspersky automatically)" -ForegroundColor DarkGray
            }
        }
    }
}

function Restore-AntivirusProtection {
    Write-Host "Restoring Antivirus settings..." -ForegroundColor Yellow

    # Re-enable Windows Defender real-time monitoring
    try {
        if (Get-Command "Set-MpPreference" -ErrorAction SilentlyContinue) {
            Set-MpPreference -DisableRealtimeMonitoring $false -ErrorAction SilentlyContinue
            Write-Host "  Windows Defender real-time monitoring restored." -ForegroundColor Green
        }
    } catch {}

    # Resume Kaspersky Endpoint Security
    $kesPaths = @(
        "$env:ProgramFiles (x86)\Kaspersky Lab\Kaspersky Endpoint Security for Windows\avp.com",
        "$env:ProgramFiles\Kaspersky Lab\Kaspersky Endpoint Security for Windows\avp.com"
    )
    foreach ($avp in $kesPaths) {
        if (Test-Path $avp) {
            try {
                Start-Process -FilePath $avp -ArgumentList "START" -NoNewWindow -Wait -ErrorAction SilentlyContinue
                Write-Host "  Kaspersky protection resumed." -ForegroundColor Green
            } catch {}
        }
    }
}

# --- Create C:\SecureDongle.dll Symlink for Standard Non-Admin User Access ---
function Setup-SecureDongleFileSymlink {
    $targetFile = "C:\ProgramData\SZC\SecureDongle.dll"
    $linkPath   = "C:\SecureDongle.dll"

    Write-Host "Setting up C:\SecureDongle.dll file symlink for non-admin user access..." -ForegroundColor Cyan

    $szcDir = Split-Path $targetFile -Parent
    if (-not (Test-Path $szcDir)) {
        New-Item -ItemType Directory -Path $szcDir -Force | Out-Null
    }

    # Ensure target file exists in ProgramData
    if (-not (Test-Path $targetFile)) {
        New-Item -ItemType File -Path $targetFile -Force | Out-Null
    }

    # Grant FullControl permissions to local users on target file
    try {
        $acl = Get-Acl $targetFile
        $rule = New-Object System.Security.AccessControl.FileSystemAccessRule(
            "Users", "FullControl", "Allow"
        )
        $acl.AddAccessRule($rule)
        Set-Acl -Path $targetFile -AclObject $acl
        Write-Host "  Granted Full Control permissions on $targetFile to local users." -ForegroundColor Green
    } catch {
        Write-Host "  (Notice: Could not update ACL permissions on $targetFile)" -ForegroundColor DarkGray
    }

    # Create Symbolic Link at C:\SecureDongle.dll if not present
    if (-not (Test-Path $linkPath)) {
        try {
            New-Item -ItemType SymbolicLink -Path $linkPath -Target $targetFile -Force | Out-Null
            Write-Host "  Created File Symlink: $linkPath -> $targetFile" -ForegroundColor Green
        } catch {
            Write-Host "  Fallback creating file symlink via cmd..." -ForegroundColor Yellow
            cmd /c "mklink `"$linkPath`" `"$targetFile`"" | Out-Null
        }

        # Also grant FullControl on the link path itself
        try {
            if (Test-Path $linkPath) {
                $linkAcl = Get-Acl $linkPath
                $rule = New-Object System.Security.AccessControl.FileSystemAccessRule("Users", "FullControl", "Allow")
                $linkAcl.AddAccessRule($rule)
                Set-Acl -Path $linkPath -AclObject $linkAcl
            }
        } catch {}
    } else {
        Write-Host "  Path $linkPath already exists. Updating ACL permissions..." -ForegroundColor DarkGray
        try {
            $linkAcl = Get-Acl $linkPath
            $rule = New-Object System.Security.AccessControl.FileSystemAccessRule("Users", "FullControl", "Allow")
            $linkAcl.AddAccessRule($rule)
            Set-Acl -Path $linkPath -AclObject $linkAcl
            Write-Host "  Granted Full Control permissions on $linkPath to local users." -ForegroundColor Green
        } catch {}
    }
}

# --- Main Installation Logic ---

Disable-AntivirusProtection

try {
    # Set up SecureDongle.dll file symlink & permissions before installing
    Setup-SecureDongleFileSymlink

    # Create cache directory
    if (-not (Test-Path $CacheDir)) {
        New-Item -ItemType Directory -Path $CacheDir -Force | Out-Null
    }

    # Download installer if not cached
    if (-not (Test-Path $InstallerPath)) {
        Write-Host "Downloading BNSC installer from Google Drive..."
        $dlHelper = Join-Path (Split-Path $MyInvocation.MyCommand.Path -Parent) "..\download_helper.ps1"
        if (Test-Path $dlHelper) { . $dlHelper }

        if (Get-Command "Start-GoogleDriveDownload" -ErrorAction SilentlyContinue) {
            Start-GoogleDriveDownload -UrlOrId $DownloadUrl -OutFile $InstallerPath
        } else {
            throw "Download helper function Start-GoogleDriveDownload not found."
        }
    } else {
        Write-Host "Using cached BNSC installer: $InstallerPath"
    }

    # Run installer
    Write-Host "Running BNSC installer..."
    $process = Start-Process -FilePath $InstallerPath -NoNewWindow -PassThru -Wait

    if ($process.ExitCode -ne 0) {
        throw "BNSC installation failed with exit code: $($process.ExitCode)"
    }

    Write-Host "BNSC installed successfully." -ForegroundColor Green
    Write-Host "  Remember to plug in the USB dongle for license activation." -ForegroundColor Yellow
}
finally {
    Restore-AntivirusProtection
}

  }
  "app/lockxls_install/install.ps1" = {
# LockXLS Installer
# Must be installed AFTER BNSC to ensure BNSC works correctly.
# Dependency chain: .NET 3.5 -> VSTOR -> Office -> BNSC -> LockXLS

$CacheDir     = "C:\ProgramData\SZC\InstallCache\lockxls"
$DownloadUrl  = "https://drive.google.com/file/d/1KdQyb6YEsB3LtDEK9cHNUfWdoULKobke/view?usp=drive_link"
$ZipName      = "lockxls_setup.zip"
$ZipPath      = Join-Path $CacheDir $ZipName
$ExtractDir   = Join-Path $CacheDir "extracted"

if ([string]::IsNullOrWhiteSpace($DownloadUrl)) {
    throw "LockXLS download URL is not configured. Update the `$DownloadUrl variable in lockxls_install/install.ps1"
}

# --- Helper functions to temporarily bypass Antivirus (Defender / KES) ---
function Disable-AntivirusProtection {
    Write-Host "Temporarily adjusting Antivirus settings for LockXLS installation..." -ForegroundColor Yellow
    try {
        if (Get-Command "Add-MpPreference" -ErrorAction SilentlyContinue) {
            Add-MpPreference -ExclusionPath $CacheDir -ErrorAction SilentlyContinue
            Add-MpPreference -ExclusionPath "C:\Program Files\LockXLS" -ErrorAction SilentlyContinue
            Add-MpPreference -ExclusionPath "C:\Program Files (x86)\LockXLS" -ErrorAction SilentlyContinue
            Set-MpPreference -DisableRealtimeMonitoring $true -ErrorAction SilentlyContinue
        }
    } catch {}

    $kesPaths = @(
        "$env:ProgramFiles (x86)\Kaspersky Lab\Kaspersky Endpoint Security for Windows\avp.com",
        "$env:ProgramFiles\Kaspersky Lab\Kaspersky Endpoint Security for Windows\avp.com"
    )
    foreach ($avp in $kesPaths) {
        if (Test-Path $avp) {
            try {
                Start-Process -FilePath $avp -ArgumentList "STOP" -NoNewWindow -Wait -ErrorAction SilentlyContinue
            } catch {}
        }
    }
}

function Restore-AntivirusProtection {
    try {
        if (Get-Command "Set-MpPreference" -ErrorAction SilentlyContinue) {
            Set-MpPreference -DisableRealtimeMonitoring $false -ErrorAction SilentlyContinue
        }
    } catch {}

    $kesPaths = @(
        "$env:ProgramFiles (x86)\Kaspersky Lab\Kaspersky Endpoint Security for Windows\avp.com",
        "$env:ProgramFiles\Kaspersky Lab\Kaspersky Endpoint Security for Windows\avp.com"
    )
    foreach ($avp in $kesPaths) {
        if (Test-Path $avp) {
            try {
                Start-Process -FilePath $avp -ArgumentList "START" -NoNewWindow -Wait -ErrorAction SilentlyContinue
            } catch {}
        }
    }
}

Disable-AntivirusProtection

try {
    # Create cache directory
    if (-not (Test-Path $CacheDir)) {
        New-Item -ItemType Directory -Path $CacheDir -Force | Out-Null
    }

    # Download installer package if not cached
    if (-not (Test-Path $ZipPath)) {
        Write-Host "Downloading LockXLS package from Google Drive..."
        $dlHelper = Join-Path (Split-Path $MyInvocation.MyCommand.Path -Parent) "..\download_helper.ps1"
        if (Test-Path $dlHelper) { . $dlHelper }

        Start-GoogleDriveDownload -UrlOrId $DownloadUrl -OutFile $ZipPath
    } else {
        Write-Host "Using cached LockXLS package: $ZipPath"
    }

    # Extract package
    Write-Host "Extracting LockXLS installer..."
    if (Test-Path $ExtractDir) {
        Remove-Item -Path $ExtractDir -Recurse -Force -ErrorAction SilentlyContinue
    }
    New-Item -ItemType Directory -Path $ExtractDir -Force | Out-Null

    try {
        Expand-Archive -Path $ZipPath -DestinationPath $ExtractDir -Force -ErrorAction Stop
    } catch {
        # Fallback to 7-Zip CLI if available
        $7zExe = Join-Path $env:ProgramFiles "7-Zip\7z.exe"
        if (Test-Path $7zExe) {
            & $7zExe x "$ZipPath" "-o$ExtractDir" -y | Out-Null
        } else {
            throw "Failed to extract LockXLS zip archive: $($_.Exception.Message)"
        }
    }

    # Find .msi inside extracted folder
    $msiFile = Get-ChildItem -Path $ExtractDir -Filter "*.msi" -Recurse | Select-Object -First 1
    if (-not $msiFile) {
        throw "No .msi installer found inside LockXLS package."
    }

    # Run MSI installer silently
    Write-Host "Executing silent LockXLS installation ($($msiFile.Name))..."
    $process = Start-Process -FilePath "msiexec.exe" `
        -ArgumentList "/i `"$($msiFile.FullName)`" /passive /norestart" `
        -NoNewWindow -PassThru -Wait

    if ($process.ExitCode -ne 0) {
        throw "LockXLS installation failed with exit code: $($process.ExitCode)"
    }

    Write-Host "LockXLS installed successfully." -ForegroundColor Green
}
finally {
    Restore-AntivirusProtection
}

  }
  "app/autocad_install/install.ps1" = {
# AutoCAD LT Custom Installer
# AutoCAD LT uses Named User licensing (sign-in based).
# The deployment package must be created once from the Autodesk Account portal
# and pre-staged to one of the search paths below.
# After installation, the end user signs in with their Autodesk account.

$CacheDir     = "C:\ProgramData\SZC\InstallCache\autocad"
$SetupExeName = "Setup.exe"

# --- Search for Setup.exe across multiple locations ---
Write-Host "Searching for AutoCAD LT installation package..."

# Build list of search paths: local cache first, then USB/removable drives
$searchPaths = @($CacheDir)

# Add all removable and fixed non-system drives (USB sticks, external drives)
try {
    $extraDrives = Get-CimInstance -ClassName Win32_LogicalDisk |
        Where-Object {
            $_.DriveType -in @(2, 3) -and   # 2=Removable, 3=Local Fixed
            $_.DeviceID -ne $env:SystemDrive  # Skip C: (system drive)
        } |
        ForEach-Object { $_.DeviceID }

    foreach ($drive in $extraDrives) {
        # Check root and common subfolder names
        $searchPaths += "$drive\"
        $searchPaths += "$drive\autocad"
        $searchPaths += "$drive\AutoCAD"
        $searchPaths += "$drive\AutoCAD LT"
        $searchPaths += "$drive\SZC\autocad"
        $searchPaths += "$drive\InstallCache\autocad"
    }
} catch {
    Write-Host "  (Could not enumerate extra drives: $($_.Exception.Message))" -ForegroundColor DarkGray
}

$foundSetup = $null
foreach ($searchPath in $searchPaths) {
    $candidate = Join-Path $searchPath $SetupExeName
    if (Test-Path $candidate) {
        $foundSetup = $candidate
        Write-Host "  Found: $candidate" -ForegroundColor Green
        break
    }
}

if (-not $foundSetup) {
    Write-Host ""
    Write-Host "  =============================================" -ForegroundColor Yellow
    Write-Host "  AutoCAD LT setup package NOT FOUND" -ForegroundColor Yellow
    Write-Host "  =============================================" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "  AutoCAD LT cannot be downloaded automatically." -ForegroundColor White
    Write-Host "  A deployment package must be prepared once" -ForegroundColor White
    Write-Host "  from the Autodesk admin portal." -ForegroundColor White
    Write-Host ""
    Write-Host "  How to prepare (one-time):" -ForegroundColor Cyan
    Write-Host "    1. Go to https://manage.autodesk.com" -ForegroundColor White
    Write-Host "    2. Sign in with your admin account" -ForegroundColor White
    Write-Host "    3. Go to Products > AutoCAD LT > Custom Install" -ForegroundColor White
    Write-Host "    4. Configure language and options" -ForegroundColor White
    Write-Host "    5. Download the deployment package" -ForegroundColor White
    Write-Host "    6. Copy the extracted folder (with Setup.exe)" -ForegroundColor White
    Write-Host "       to one of these locations:" -ForegroundColor White
    Write-Host "       - $CacheDir" -ForegroundColor Gray
    Write-Host "       - USB drive root or \autocad subfolder" -ForegroundColor Gray
    Write-Host ""
    Write-Host "  After install, the user signs in with their" -ForegroundColor DarkGray
    Write-Host "  Autodesk account to activate the license." -ForegroundColor DarkGray
    Write-Host ""
    Write-Host "  Searched locations:" -ForegroundColor DarkGray
    foreach ($p in $searchPaths) {
        $status = if (Test-Path $p) { "[exists, no Setup.exe]" } else { "[not found]" }
        Write-Host "    $p $status" -ForegroundColor DarkGray
    }
    Write-Host ""

    # Offer to open the Autodesk portal
    try {
        $openPortal = Read-Host "  Open Autodesk portal in browser? (Y/N)"
        if ($openPortal -eq "Y" -or $openPortal -eq "y") {
            Start-Process "https://manage.autodesk.com/products"
            Write-Host "  Opened browser. Re-run deployment after preparing the package." -ForegroundColor Green
        }
    } catch {
        # Non-critical, ignore
    }

    Write-Host ""
    Write-Host "  Skipping AutoCAD LT installation." -ForegroundColor Yellow
    return
}

# --- Run the installer ---
Write-Host "Using AutoCAD LT setup package at: $foundSetup" -ForegroundColor Cyan

# If found on USB/external drive, copy to local cache first for reliability
$setupDir = Split-Path $foundSetup -Parent
if ($setupDir -ne $CacheDir) {
    Write-Host "  Copying deployment files to local cache: $CacheDir ..."
    if (-not (Test-Path $CacheDir)) {
        New-Item -ItemType Directory -Path $CacheDir -Force | Out-Null
    }
    Copy-Item -Path "$setupDir\*" -Destination $CacheDir -Recurse -Force
    $foundSetup = Join-Path $CacheDir $SetupExeName
    Write-Host "  Copy complete." -ForegroundColor Green
}

Write-Host "Executing silent AutoCAD LT installation..."
Write-Host "  (User will sign in with Autodesk account after install)" -ForegroundColor DarkGray
$process = Start-Process -FilePath $foundSetup -ArgumentList "-q" -NoNewWindow -PassThru -Wait

if ($process.ExitCode -ne 0) {
    throw "AutoCAD LT installation failed with exit code: $($process.ExitCode)"
}

Write-Host "AutoCAD LT installed successfully."
Write-Host "  Remind the user to sign in with their Autodesk account to activate." -ForegroundColor Yellow

  }
  "app/netfx35_install/install.ps1" = {
# .NET Framework 3.5 Installer (includes .NET 2.0 and 3.0)
# Uses DISM to enable the Windows optional feature.
# Requires internet access for Windows Update to download components.

Write-Host "Checking if .NET Framework 3.5 is already enabled..."

$feature = Get-WindowsOptionalFeature -Online -FeatureName "NetFx3" -ErrorAction SilentlyContinue

if ($feature -and $feature.State -eq "Enabled") {
    Write-Host ".NET Framework 3.5 is already enabled. Skipping."
    return
}

Write-Host "Enabling .NET Framework 3.5 (includes .NET 2.0 and 3.0)..."
Write-Host "  This may take a few minutes (downloading from Windows Update)..."

try {
    Enable-WindowsOptionalFeature -Online -FeatureName "NetFx3" -All -NoRestart -ErrorAction Stop
    Write-Host ".NET Framework 3.5 enabled successfully."
} catch {
    # Fallback to DISM if the PowerShell cmdlet fails
    Write-Host "  PowerShell method failed, trying DISM..."
    $dismResult = Start-Process -FilePath "dism.exe" `
        -ArgumentList "/online /Enable-Feature /FeatureName:NetFx3 /All /NoRestart" `
        -NoNewWindow -PassThru -Wait

    if ($dismResult.ExitCode -ne 0) {
        throw ".NET Framework 3.5 installation failed (DISM exit code: $($dismResult.ExitCode)). Ensure internet access is available."
    }
    Write-Host ".NET Framework 3.5 enabled successfully via DISM."
}

  }
}

function Install-App
{
  [CmdletBinding()]
  param (
    [String]$Name,
    [String]$PackageName,
    [String]$PackageManager,
    [String]$CustomScript,
    [String[]]$InstallArgs
  )

  if ($CustomScript)
  {
    Write-Host "Running custom installer for $Name..." -ForegroundColor Cyan
    $normalizedKey = $CustomScript.Replace('\', '/')
    if ($script:EmbeddedCustomScripts.ContainsKey($normalizedKey))
    {
      & $script:EmbeddedCustomScripts[$normalizedKey]
    }
    elseif (Test-Path $CustomScript)
    {
      $scriptDir = Split-Path $CustomScript -Parent
      Push-Location $scriptDir
      try { . $CustomScript } finally { Pop-Location }
    }
    else
    {
      throw "Custom script not found: $CustomScript"
    }
  }
  else
  {
    $Command = @("install", "-e", "--id", $PackageName,
                 "--accept-package-agreements", "--accept-source-agreements", "-h")
    
    if ($InstallArgs -and $InstallArgs.Count -gt 0)
    {
      $Command += $InstallArgs
    }
    
    Write-Host "Running: $PackageManager $($Command -join ' ')"
    & $PackageManager @Command

    if ($LASTEXITCODE -and $LASTEXITCODE -ne 0)
    {
      throw "'$Name' installer exited with code $LASTEXITCODE."
    }
  }

  Write-Host "Successfully installed: $Name" -ForegroundColor Green
}

# --- TUI COMPONENTS ---
function Write-Header ($Title)
{
  Write-Host "==================================================" -ForegroundColor Cyan
  Write-Host "         $Title" -ForegroundColor Green
  Write-Host "==================================================" -ForegroundColor Cyan
}

function Write-Footer
{
  Write-Host "==================================================" -ForegroundColor Cyan
}

function Write-Divider
{
  Write-Host "--------------------------------------------------"
}

function Show-PressEnterToContinue ($Message = "Press Enter to return to main menu...")
{
  Write-Host $Message
  Read-Host | Out-Null
}

function Show-AppSelectionMenu
{
  while ($true)
  {
    Clear-Host
    Write-Header "SELECT APPLICATIONS TO INSTALL"

    for ($i = 0; $i -lt $CommonApps.Count; $i++)
    {
      $app = $CommonApps[$i]
      $checkbox = if ($script:selectedApps[$app.Id])
      { "[X]"
      } else
      { "[ ]"
      }
      $num = ($i + 1).ToString().PadLeft(2)
      Write-Host "  $num. $checkbox $($app.Name)"
    }

    Write-Divider
    $selectAll = $CommonApps.Count + 1
    $selectNone = $CommonApps.Count + 2
    $goBack = $CommonApps.Count + 3
    Write-Host "  $selectAll. Select All"
    Write-Host "  $selectNone. Deselect All"
    Write-Host "  $goBack. Return to Main Menu"
    Write-Footer

    $actionInput = (Read-Host "Choose (1-$goBack)").Trim()
    $val = 0

    if ([int]::TryParse($actionInput, [ref]$val))
    {
      if ($val -ge 1 -and $val -le $CommonApps.Count)
      {
        $app = $CommonApps[$val - 1]
        $script:selectedApps[$app.Id] = !$script:selectedApps[$app.Id]
        $script:currentDepartmentName = "Custom"
      } elseif ($val -eq $selectAll)
      {
        foreach ($app in $CommonApps)
        { $script:selectedApps[$app.Id] = $true
        }
        $script:currentDepartmentName = "Custom"
      } elseif ($val -eq $selectNone)
      {
        foreach ($app in $CommonApps)
        { $script:selectedApps[$app.Id] = $false
        }
        $script:currentDepartmentName = "Custom"
      } elseif ($val -eq $goBack)
      {
        return
      } else
      {
        Write-Host "Invalid option, press Enter to try again..." -ForegroundColor Red
        Read-Host | Out-Null
      }
    } else
    {
      Write-Host "Please enter a number only. Press Enter to try again..." -ForegroundColor Red
      Read-Host | Out-Null
    }
  }
}

function Show-PrinterSelectionMenu
{
  while ($true)
  {
    Clear-Host
    Write-Header "SELECT PRINTERS TO INSTALL"

    if ($Printers.Count -eq 0)
    {
      Write-Host "  No printers configured yet." -ForegroundColor Yellow
      Write-Divider
      Write-Host "  1. Return to Main Menu"
      Write-Footer

      $actionInput = (Read-Host "Choose (1)").Trim()
      if ($actionInput -eq "1") { return }
      continue
    }

    for ($i = 0; $i -lt $Printers.Count; $i++)
    {
      $printer = $Printers[$i]
      $checkbox = if ($script:selectedPrinters[$printer.Id])
      { "[X]"
      } else
      { "[ ]"
      }
      $num = ($i + 1).ToString().PadLeft(2)
      Write-Host "  $num. $checkbox $($printer.Name) ($($printer.Url))"
    }

    Write-Divider
    $selectAll = $Printers.Count + 1
    $selectNone = $Printers.Count + 2
    $goBack = $Printers.Count + 3
    Write-Host "  $selectAll. Select All"
    Write-Host "  $selectNone. Deselect All"
    Write-Host "  $goBack. Return to Main Menu"
    Write-Footer

    $actionInput = (Read-Host "Choose (1-$goBack)").Trim()
    $val = 0

    if ([int]::TryParse($actionInput, [ref]$val))
    {
      if ($val -ge 1 -and $val -le $Printers.Count)
      {
        $printer = $Printers[$val - 1]
        $script:selectedPrinters[$printer.Id] = !$script:selectedPrinters[$printer.Id]
        $script:currentDepartmentName = "Custom"
      } elseif ($val -eq $selectAll)
      {
        foreach ($printer in $Printers)
        { $script:selectedPrinters[$printer.Id] = $true
        }
        $script:currentDepartmentName = "Custom"
      } elseif ($val -eq $selectNone)
      {
        foreach ($printer in $Printers)
        { $script:selectedPrinters[$printer.Id] = $false
        }
        $script:currentDepartmentName = "Custom"
      } elseif ($val -eq $goBack)
      {
        return
      } else
      {
        Write-Host "Invalid option, press Enter to try again..." -ForegroundColor Red
        Read-Host | Out-Null
      }
    } else
    {
      Write-Host "Please enter a number only. Press Enter to try again..." -ForegroundColor Red
      Read-Host | Out-Null
    }
  }
}

function Get-SystemInformation
{
  Clear-Host
  Write-Header "COLLECTING SYSTEM INFORMATION"
  Write-Host ""
  
  try
  {
    $os = Get-CimInstance Win32_OperatingSystem -ErrorAction Stop
    $cpu = Get-CimInstance Win32_Processor -ErrorAction Stop
    $cs = Get-CimInstance Win32_ComputerSystem -ErrorAction Stop
    $ramGB = [Math]::Round((Get-CimInstance Win32_PhysicalMemory -ErrorAction SilentlyContinue | Measure-Object Capacity -Sum).Sum / 1GB, 2)
    $disks = (Get-CimInstance Win32_LogicalDisk | Where-Object DriveType -eq 3 | ForEach-Object { "$($_.DeviceID) (Free: $([Math]::Round($_.FreeSpace / 1GB, 1)) GB / Total: $([Math]::Round($_.Size / 1GB, 1)) GB)" }) -join ", "
    $ips = (Get-NetIPAddress -AddressFamily IPv4 -InterfaceAlias "Wi-Fi", "Ethernet" -ErrorAction SilentlyContinue | Select-Object -ExpandProperty IPAddress) -join ", "
    $macs = (Get-NetAdapter | Where-Object Status -eq "Up" | Select-Object -ExpandProperty MacAddress -ErrorAction SilentlyContinue) -join ", "
    
    $sysInfo = [ordered]@{
      "Computer Name"   = $env:COMPUTERNAME
      "Current User"    = "$env:USERDOMAIN\$env:USERNAME"
      "OS Version"      = $os.Caption
      "OS Build"        = $os.Version
      "Architecture"    = $os.OSArchitecture
      "CPU"             = $cpu.Name
      "RAM Capacity"    = "$ramGB GB"
      "Disk Space"      = $disks
      "IP Address"      = $ips
      "MAC Address"     = $macs
      "Domain/Workgroup"= $cs.Domain
    }

    foreach ($key in $sysInfo.Keys)
    {
      Write-Host "$($key.PadRight(18)): $($sysInfo[$key])" -ForegroundColor Yellow
    }
    
    Write-Divider
    
    $destDir = "C:\ProgramData\SZC"
    if (!(Test-Path $destDir))
    {
      New-Item -ItemType Directory -Path $destDir -Force | Out-Null
    }
    $destFile = Join-Path $destDir "SystemInfo_$($env:COMPUTERNAME).txt"
    
    $report = New-Object System.Text.StringBuilder
    $report.AppendLine("==================================================") | Out-Null
    $report.AppendLine("            SYSTEM INFORMATION REPORT             ") | Out-Null
    $report.AppendLine("==================================================") | Out-Null
    foreach ($key in $sysInfo.Keys)
    {
      $report.AppendLine("$($key.PadRight(18)): $($sysInfo[$key])") | Out-Null
    }
    $report.AppendLine("==================================================") | Out-Null
    
    $report.ToString() | Out-File -FilePath $destFile -Force
    
    Write-Host "Report saved to: $destFile" -ForegroundColor Green
  } catch
  {
    Write-Error "Failed to retrieve system information: $($_.Exception.Message)"
  }
  
  Write-Footer
  Show-PressEnterToContinue
}


# --- TUI COORDINATOR ---
$_apps = $script:Embedded_AppsJson | ConvertFrom-Json
$CommonApps = foreach ($app in ($_apps | Where-Object { -not $_.disabled })) {
  $customScript = ""
  if ($app.customScript) {
    $customScript = $app.customScript
  }
  $deps = @()
  if ($app.dependencies) {
    $deps = @($app.dependencies)
  }
  @{
    Id             = $app.id
    Name           = $app.name
    Package        = $app.package
    PackageManager = $app.packageManager
    CustomScript   = $customScript
    Dependencies   = $deps
    InstallArgs    = @($app.installArgs)
  }
}

$_printers = $script:Embedded_PrintersJson | ConvertFrom-Json
$Printers = foreach ($printer in $_printers) {
  $dup = if ($printer.duplex) { $printer.duplex } elseif ($printer.duplexMode) { $printer.duplexMode } else { $null }
  @{
    Id                = $printer.id
    Name              = $printer.name
    Url               = $printer.url
    Port              = $printer.port
    PortType          = $printer.portType
    LprQueue          = $printer.lprQueue
    Driver            = $printer.driver
    DriverUrl         = $printer.driverUrl
    DriverInstallArgs = @($printer.driverInstallArgs)
    IppPath           = $printer.ippPath
    PaperSize         = $printer.paperSize
    Duplex            = $dup
  }
}

$script:Departments = $script:Embedded_DepartmentsJson | ConvertFrom-Json

$script:selectedApps = @{}
$script:selectedPrinters = @{}
$script:currentDepartmentName = ""

function Apply-DepartmentProfile ($dept)
{
  foreach ($app in $CommonApps) { $script:selectedApps[$app.Id] = $false }
  foreach ($printer in $Printers) { $script:selectedPrinters[$printer.Id] = $false }
  foreach ($appId in $dept.apps) { $script:selectedApps[$appId] = $true }
  foreach ($printerId in $dept.printers) { $script:selectedPrinters[$printerId] = $true }
  $script:currentDepartmentName = $dept.name
}

foreach ($app in $CommonApps) { $script:selectedApps[$app.Id] = $false }
foreach ($printer in $Printers) { $script:selectedPrinters[$printer.Id] = $false }
$script:currentDepartmentName = "None"

function Show-DepartmentMenu
{
  while ($true)
  {
    Clear-Host
    Write-Header "SELECT USER DEPARTMENT PROFILE"
    Write-Host ""

    for ($i = 0; $i -lt $script:Departments.Count; $i++)
    {
      $dept = $script:Departments[$i]
      $num = ($i + 1).ToString().PadLeft(2)
      Write-Host "  $num. $($dept.name)"
    }

    $customNum = $script:Departments.Count + 1
    $backNum   = $script:Departments.Count + 2
    Write-Host "  $($customNum.ToString().PadLeft(2)). Custom (Manual Selection)"
    Write-Divider
    Write-Host "  $($backNum.ToString().PadLeft(2)). Return to Main Menu"
    Write-Host ""
    Write-Host "  Selecting a profile presets apps & printers." -ForegroundColor Yellow
    Write-Footer

    $actionInput = (Read-Host "Choose (1-$backNum)").Trim()
    $val = 0

    if ([int]::TryParse($actionInput, [ref]$val))
    {
      if ($val -ge 1 -and $val -le $script:Departments.Count)
      {
        $dept = $script:Departments[$val - 1]
        Apply-DepartmentProfile $dept
        return
      } elseif ($val -eq $customNum)
      {
        $script:currentDepartmentName = "Custom"
        return
      } elseif ($val -eq $backNum)
      {
        return
      } else
      {
        Write-Host "Invalid option, press Enter to try again..." -ForegroundColor Red
        Read-Host | Out-Null
      }
    } else
    {
      Write-Host "Please enter a number only. Press Enter to try again..." -ForegroundColor Red
      Read-Host | Out-Null
    }
  }
}

function Start-Deployment
{
  Clear-Host
  $appsToInstall     = $CommonApps | Where-Object { $script:selectedApps[$_.Id] }
  $printersToInstall = $Printers | Where-Object { $script:selectedPrinters[$_.Id] }

  if ($appsToInstall.Count -eq 0 -and $printersToInstall.Count -eq 0)
  {
    Write-Host "  No applications or printers selected for installation." -ForegroundColor Yellow
    Show-PressEnterToContinue
    return
  }

  $selectedIds = [System.Collections.Generic.HashSet[string]]::new()
  foreach ($app in $appsToInstall) { $selectedIds.Add($app.Id) | Out-Null }

  $depsAdded = @()
  foreach ($app in $appsToInstall)
  {
    foreach ($depId in $app.Dependencies)
    {
      if (-not $selectedIds.Contains($depId))
      {
        $selectedIds.Add($depId) | Out-Null
        $depsAdded += $depId
      }
    }
  }

  if ($depsAdded.Count -gt 0)
  {
    $depApps = $CommonApps | Where-Object { $depsAdded -contains $_.Id }
    $appsToInstall = @($depApps) + @($appsToInstall)
  }
  else
  {
    $orderedList = [System.Collections.Generic.List[hashtable]]::new()
    $addedIds = [System.Collections.Generic.HashSet[string]]::new()
    foreach ($app in $appsToInstall)
    {
      foreach ($depId in $app.Dependencies)
      {
        if (-not $addedIds.Contains($depId))
        {
          $depApp = $CommonApps | Where-Object { $_.Id -eq $depId } | Select-Object -First 1
          if ($depApp) { $orderedList.Add($depApp); $addedIds.Add($depId) | Out-Null }
        }
      }
      if (-not $addedIds.Contains($app.Id))
      {
        $orderedList.Add($app)
        $addedIds.Add($app.Id) | Out-Null
      }
    }
    $appsToInstall = $orderedList.ToArray()
  }

  Write-Header "CONFIRM DEPLOYMENT"
  Write-Host "  Profile: $($script:currentDepartmentName)" -ForegroundColor Yellow
  Write-Host ""

  if ($appsToInstall.Count -gt 0)
  {
    Write-Host "  Applications to install:" -ForegroundColor Cyan
    foreach ($app in $appsToInstall)
    { Write-Host "    - $($app.Name)" }
  }

  if ($printersToInstall.Count -gt 0)
  {
    Write-Host ""
    Write-Host "  Printers to install:" -ForegroundColor Cyan
    foreach ($p in $printersToInstall)
    { Write-Host "    - $($p.Name) ($($p.Url))" }
  }

  Write-Divider
  Write-Host "  1. Start Deployment"
  Write-Host "  2. Cancel"
  Write-Footer

  $confirm = (Read-Host "Choose (1-2)").Trim()
  if ($confirm -ne "1")
  {
    Write-Host "  Deployment cancelled." -ForegroundColor Yellow
    Show-PressEnterToContinue
    return
  }

  $appResults     = [System.Collections.Generic.List[hashtable]]::new()
  $printerResults = [System.Collections.Generic.List[hashtable]]::new()

  Clear-Host
  Write-Header "DEPLOYMENT IN PROGRESS"
  Write-Host ""

  if ($appsToInstall.Count -gt 0)
  {
    Write-Host "  [*] Installing applications..." -ForegroundColor Cyan
    Write-Host ""
    foreach ($app in $appsToInstall)
    {
      Write-Host "  --> $($app.Name)..." -ForegroundColor Yellow -NoNewline
      $result = @{ Name = $app.Name; Status = ""; Error = "" }
      try
      {
        Install-App -Name $app.Name -PackageName $app.Package -PackageManager $app.PackageManager -CustomScript $app.CustomScript -InstallArgs $app.InstallArgs
        $result.Status = "OK"
        Write-Host " Done" -ForegroundColor Green
      } catch
      {
        $result.Status = "FAILED"
        $result.Error  = $_.Exception.Message
        Write-Host " FAILED" -ForegroundColor Red
        Write-Host "      $($_.Exception.Message)" -ForegroundColor DarkRed
      }
      $appResults.Add($result)
    }
  }

  if ($printersToInstall.Count -gt 0)
  {
    Write-Host ""
    Write-Host "  [*] Installing printers..." -ForegroundColor Cyan
    Write-Host ""
    foreach ($printer in $printersToInstall)
    {
      Write-Host "  --> $($printer.Name) ($($printer.Url))..." -ForegroundColor Yellow -NoNewline
      $result = @{ Name = $printer.Name; Status = ""; Error = "" }
      try
      {
        Install-LocalPrinter -Name $printer.Name -Url $printer.Url `
          -Port $printer.Port -PortType $printer.PortType `
          -LprQueue $printer.LprQueue -Driver $printer.Driver `
          -DriverUrl $printer.DriverUrl -DriverInstallArgs $printer.DriverInstallArgs `
          -IppPath $printer.IppPath -PaperSize $printer.PaperSize -Duplex $printer.Duplex
        $result.Status = "OK"
        Write-Host " Done" -ForegroundColor Green
      } catch
      {
        $result.Status = "FAILED"
        $result.Error  = $_.Exception.Message
        Write-Host " FAILED" -ForegroundColor Red
        Write-Host "      $($_.Exception.Message)" -ForegroundColor DarkRed
      }
      $printerResults.Add($result)
    }
  }

  Write-Host ""
  Write-Header "DEPLOYMENT SUMMARY"
  Write-Host "  Profile : $($script:currentDepartmentName)" -ForegroundColor Yellow
  Write-Host "  Finished: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Yellow
  Write-Host ""

  if ($appResults.Count -gt 0)
  {
    Write-Host "  APPLICATIONS" -ForegroundColor Cyan
    Write-Host "  ------------"
    foreach ($r in $appResults)
    {
      if ($r.Status -eq "OK")
      { Write-Host "  [ OK ]  $($r.Name)" -ForegroundColor Green }
      else
      {
        Write-Host "  [FAIL]  $($r.Name)" -ForegroundColor Red
        if ($r.Error) { Write-Host "          $($r.Error)" -ForegroundColor DarkRed }
      }
    }
    $okCount   = ($appResults | Where-Object { $_.Status -eq "OK" }).Count
    $failCount = $appResults.Count - $okCount
    Write-Host ""
    Write-Host "  Result: $okCount / $($appResults.Count) installed." -ForegroundColor $(if ($failCount -eq 0) { "Green" } else { "Yellow" })
  }

  if ($printerResults.Count -gt 0)
  {
    Write-Host ""
    Write-Host "  PRINTERS" -ForegroundColor Cyan
    Write-Host "  --------"
    foreach ($r in $printerResults)
    {
      if ($r.Status -eq "OK")
      { Write-Host "  [ OK ]  $($r.Name)" -ForegroundColor Green }
      else
      {
        Write-Host "  [FAIL]  $($r.Name)" -ForegroundColor Red
        if ($r.Error) { Write-Host "          $($r.Error)" -ForegroundColor DarkRed }
      }
    }
    $pOk   = ($printerResults | Where-Object { $_.Status -eq "OK" }).Count
    $pFail = $printerResults.Count - $pOk
    Write-Host ""
    Write-Host "  Result: $pOk / $($printerResults.Count) installed." -ForegroundColor $(if ($pFail -eq 0) { "Green" } else { "Yellow" })
  }

  Write-Host ""
  Write-Footer
  Show-PressEnterToContinue
}

function Show-MainMenu
{
  while ($true)
  {
    Clear-Host
    Write-Header "SZC AUTOMATED DEPLOYMENT TOOL"
    Write-Host " Active Profile: $($script:currentDepartmentName)" -ForegroundColor Yellow
    
    $appCount = ($script:selectedApps.Values | Where-Object { $_ }).Count
    $printerCount = ($script:selectedPrinters.Values | Where-Object { $_ }).Count
    Write-Host " Selected: $appCount/$($CommonApps.Count) Apps, $printerCount/$($Printers.Count) Printers"
    Write-Footer
    Write-Host "  1. Select User Department Profile"
    Write-Host "  2. Customize Selected Applications"
    Write-Host "  3. Customize Selected Printers"
    Write-Host "  4. Collect User & System Information"
    Write-Host "  5. Start Deployment"
    Write-Host "  6. Exit"
    Write-Footer
    Write-Host ""
    
    $choice = (Read-Host "Choose an option (1-6)").Trim()
    
    switch ($choice)
    {
      "1" { Show-DepartmentMenu }
      "2" { Show-AppSelectionMenu }
      "3" { Show-PrinterSelectionMenu }
      "4" { Get-SystemInformation }
      "5" { Start-Deployment }
      "6"
      { 
        Write-Host "Exiting. Goodbye!" -ForegroundColor Yellow
        return
      }
      default
      {
        Write-Host "Invalid choice, press Enter to try again..." -ForegroundColor Red
        Read-Host | Out-Null
      }
    }
  }
}

function Start-Tui
{
  Show-MainMenu
}

# --- LAUNCH DEPLOYMENT ---
Start-Tui
Write-Host ""
Write-Host "Session ended. Press Enter to close this window..." -ForegroundColor DarkGray
Read-Host | Out-Null
