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

