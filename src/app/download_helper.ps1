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

  # Fallback to single-connection download if Range header is unsupported or size unknown
  if ($fileSize -le 0 -or $acceptRanges -ne "bytes")
  {
    Write-Host "  Multi-connection not supported by server. Using BITS Transfer..." -ForegroundColor Yellow
    try
    {
      Start-BitsTransfer -Source $Url -Destination $OutFile -ErrorAction Stop
      Write-Host "  Download completed via BITS Transfer." -ForegroundColor Green
      return
    }
    catch
    {
      Write-Host "  BITS Transfer failed: $($_.Exception.Message). Falling back to WebClient..." -ForegroundColor Yellow
      if (Test-Path $OutFile) { Remove-Item $OutFile -Force }

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

  $totalMB = [math]::Round($fileSize / 1MB, 2)
  Write-Host "  File size: $totalMB MB | Connections: $Connections" -ForegroundColor Cyan

  # --- Step 2: Calculate chunk byte ranges ---
  $chunkSize = [math]::Ceiling($fileSize / $Connections)
  $chunks = @()
  for ($i = 0; $i -lt $Connections; $i++)
  {
    $start = [long]($i * $chunkSize)
    $end   = [math]::Min([long](($i + 1) * $chunkSize - 1), [long]($fileSize - 1))
    $partFile = "$OutFile.part$i"
    if (Test-Path $partFile) { Remove-Item $partFile -Force }
    $chunks += @{ Index = $i; Start = $start; End = $end; File = $partFile }
  }

  # --- Step 3: Define worker script block ---
  $workerBlock = {
    param([string]$chunkUrl, [long]$rangeStart, [long]$rangeEnd, [string]$partFile)
    $req = [System.Net.HttpWebRequest]::Create($chunkUrl)
    $req.AddRange([long]$rangeStart, [long]$rangeEnd)
    $req.Timeout = 600000  # 10 minute timeout per chunk
    $resp = $req.GetResponse()
    $stream = $resp.GetResponseStream()
    $fs = [System.IO.File]::Create($partFile)
    try
    {
      $buffer = New-Object byte[] 131072  # 128KB buffer
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
    foreach ($chunk in $chunks)
    {
      if (Test-Path $chunk.File)
      {
        $downloadedBytes += (Get-Item $chunk.File -ErrorAction SilentlyContinue).Length
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
    $statusText   = "$downloadedMB MB / $totalMB MB ($percent%) | Speed: $speedMBps MB/s"

    Write-Progress -Activity $ActivityName -Status $statusText -PercentComplete ([int]$percent)

    if ($pending.Count -eq 0) { break }
    Start-Sleep -Milliseconds 300
  }

  # Complete progress bar
  Write-Progress -Activity $ActivityName -Status "Download complete ($totalMB MB)" -Completed

  # --- Step 6: Collect errors and clean up runspaces ---
  $errors = @()
  foreach ($h in $handles)
  {
    try
    {
      $h.PS.EndInvoke($h.Async)
    }
    catch
    {
      $errors += "Chunk $($h.Chunk.Index) failed: $($_.Exception.Message)"
    }
    $h.PS.Dispose()
  }
  $pool.Close()
  $pool.Dispose()

  if ($errors.Count -gt 0)
  {
    foreach ($chunk in $chunks)
    {
      if (Test-Path $chunk.File) { Remove-Item $chunk.File -Force -ErrorAction SilentlyContinue }
    }
    throw "Multi-connection download failed: $($errors -join '; ')"
  }

  # --- Step 7: Merge chunk files into target ---
  Write-Host "  Merging $Connections download parts into destination..." -ForegroundColor Cyan
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
  Write-Host "  Download complete: $finalMB MB in $totalTime seconds." -ForegroundColor Green
}
