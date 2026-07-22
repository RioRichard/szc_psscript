$Url      = "https://aes.s.kaspersky-labs.com/endpoints/keswin11/14.0.0.504/vietnamese-INT-21.25.7.504.0.143.0/a0b3932eaa6c05bcb1ae932d500116a2/keswin_14.0.0.504_vi_aes56.exe"
$CacheDir = "C:\ProgramData\SZC\InstallCache"
$KesDir   = Join-Path $CacheDir "kes_extracted"

# Ensure directories exist
New-Item -ItemType Directory -Force -Path $CacheDir  | Out-Null
New-Item -ItemType Directory -Force -Path $KesDir    | Out-Null

# --- Step 1: Download the NSIS self-extracting archive ---
$DownloadedExe = Join-Path $CacheDir "keswin_setup.exe"
$ArchiveAs7z   = Join-Path $CacheDir "keswin_setup.7z"

# Remove leftover download if present
if (Test-Path $DownloadedExe) { Remove-Item $DownloadedExe -Force }

# --- Multi-connection download function ---
# Splits the file into chunks and downloads them in parallel using HTTP Range
# requests and PowerShell runspaces. Falls back to single-connection if the
# server does not support Range requests.
function Download-MultiConnection
{
  param(
    [string]$SourceUrl,
    [string]$OutFile,
    [int]$Connections = 8
  )

  # Step 1: HEAD request to get file size and check Range support
  Write-Host "  Checking server..."
  $headReq = [System.Net.HttpWebRequest]::Create($SourceUrl)
  $headReq.Method = "HEAD"
  $headReq.Timeout = 30000
  try
  {
    $headResp = $headReq.GetResponse()
    $fileSize = $headResp.ContentLength
    $acceptRanges = $headResp.Headers["Accept-Ranges"]
    $headResp.Close()
  }
  catch
  {
    Write-Host "  HEAD request failed, using single connection." -ForegroundColor Yellow
    $fileSize = -1
  }

  # Fall back to single connection if Range not supported or file size unknown
  if ($fileSize -le 0 -or $acceptRanges -ne "bytes")
  {
    Write-Host "  Server does not support multi-connection. Downloading with BITS..."
    try
    {
      Start-BitsTransfer -Source $SourceUrl -Destination $OutFile -ErrorAction Stop
      return
    }
    catch
    {
      Write-Host "  BITS failed, trying WebClient..." -ForegroundColor Yellow
      $wc = New-Object System.Net.WebClient
      try { $wc.DownloadFile($SourceUrl, $OutFile) }
      finally { $wc.Dispose() }
      return
    }
  }

  $sizeMB = [math]::Round($fileSize / 1MB, 1)
  Write-Host "  File size: $sizeMB MB -- using $Connections parallel connections..."

  # Step 2: Calculate chunk byte ranges
  $chunkSize = [math]::Ceiling($fileSize / $Connections)
  $chunks = @()
  for ($i = 0; $i -lt $Connections; $i++)
  {
    $start = [long]($i * $chunkSize)
    $end   = [math]::Min([long](($i + 1) * $chunkSize - 1), [long]($fileSize - 1))
    $partFile = "$OutFile.part$i"
    $chunks += @{ Index = $i; Start = $start; End = $end; File = $partFile }
  }

  # Step 3: Download each chunk in parallel using runspaces
  $scriptBlock = {
    param([string]$url, [long]$rangeStart, [long]$rangeEnd, [string]$partFile)
    $req = [System.Net.HttpWebRequest]::Create($url)
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

  $pool = [runspacefactory]::CreateRunspacePool(1, $Connections)
  $pool.Open()

  $handles = @()
  foreach ($chunk in $chunks)
  {
    $ps = [powershell]::Create()
    $ps.RunspacePool = $pool
    $ps.AddScript($scriptBlock) | Out-Null
    $ps.AddArgument($SourceUrl) | Out-Null
    $ps.AddArgument($chunk.Start) | Out-Null
    $ps.AddArgument($chunk.End) | Out-Null
    $ps.AddArgument($chunk.File) | Out-Null
    $asyncResult = $ps.BeginInvoke()
    $handles += @{ PS = $ps; Async = $asyncResult; Chunk = $chunk }
  }

  # Wait for all chunks and collect errors
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
    # Clean up partial files
    foreach ($chunk in $chunks)
    {
      if (Test-Path $chunk.File) { Remove-Item $chunk.File -Force }
    }
    throw "Multi-connection download failed: $($errors -join '; ')"
  }

  # Step 4: Merge chunks into the final file
  Write-Host "  Merging $($chunks.Count) parts..."
  $outStream = [System.IO.File]::Create($OutFile)
  try
  {
    foreach ($chunk in ($chunks | Sort-Object { $_.Index }))
    {
      $partStream = [System.IO.File]::OpenRead($chunk.File)
      try { $partStream.CopyTo($outStream) }
      finally { $partStream.Close() }
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
  Write-Host "  Download complete: $([math]::Round($finalSize / 1MB, 1)) MB"
}

Write-Host "Downloading Kaspersky Endpoint Security..."
Download-MultiConnection -SourceUrl $Url -OutFile $DownloadedExe -Connections 8

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

# --- Step 5: Find the real setup executable inside the extracted folder ---
$realInstaller = Get-ChildItem -Path $KesDir -Filter "setup*.exe" -Recurse -ErrorAction SilentlyContinue |
  Select-Object -First 1

if (-not $realInstaller)
{
  # Fallback: maybe it's an MSI installer instead
  $realInstaller = Get-ChildItem -Path $KesDir -Filter "*.msi" -Recurse -ErrorAction SilentlyContinue |
    Select-Object -First 1
}

if (-not $realInstaller)
{
  # Fallback 2: any .exe that isn't the archive itself
  $realInstaller = Get-ChildItem -Path $KesDir -Filter "*.exe" -Recurse -ErrorAction SilentlyContinue |
    Select-Object -First 1
}

if (-not $realInstaller)
{
  throw "Could not find a setup executable or MSI package inside the extracted KES package at: $KesDir"
}

Write-Host "Found installer: $($realInstaller.FullName)"

# --- Step 6: Run the real installer silently ---
Write-Host "Running Kaspersky installation silently..."

if ($realInstaller.Extension -eq ".msi")
{
  $installProc = Start-Process `
    -FilePath "msiexec.exe" `
    -ArgumentList @("/i", "`"$($realInstaller.FullName)`"", "EULA=1", "PRIVACYPOLICY=1", "/qn") `
    -NoNewWindow `
    -PassThru `
    -Wait
}
else
{
  $installProc = Start-Process `
    -FilePath $realInstaller.FullName `
    -ArgumentList @("/s", "/pEULA=1", "/pPRIVACYPOLICY=1") `
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
