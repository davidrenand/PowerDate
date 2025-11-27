# CloudFare v4.0 Installation Launcher

$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"

Write-Host ""
Write-Host "CloudFare v4.0 - Installation Orchestration" -F Green
Write-Host "Repository: PowerDate (v4.0 Official)" -F Cyan
Write-Host ""

# Step 1: Verify internet
Write-Host "STEP 1: Verifying internet connection..." -F Yellow
try {
    $response = Invoke-WebRequest -Uri "https://github.com" -Method Head -TimeoutSec 5 -ErrorAction Stop
    Write-Host "  OK: Internet available" -F Green
}
catch {
    Write-Host "  ERROR: Cannot reach GitHub" -F Red
    Write-Host "  Check your internet connection" -F Yellow
    exit 1
}

# Step 2: Download orchestrator
Write-Host ""
Write-Host "STEP 2: Downloading orchestrator..." -F Yellow

$url = "https://raw.githubusercontent.com/davidrenand/PowerDate/main/Install-Universal-v4.ps1"
$tempPath = [System.IO.Path]::GetTempPath()
$orchPath = "$tempPath\Install-Universal-v4.ps1"

try {
    Write-Host "  URL: $url" -F Cyan
    $web = New-Object System.Net.WebClient
    $web.DownloadFile($url, $orchPath)
    Write-Host "  OK: Orchestrator downloaded" -F Green
}
catch {
    Write-Host "  ERROR: Download failed" -F Red
    Write-Host "  Details: $_" -F Yellow
    exit 1
}

# Step 3: Execute orchestrator
Write-Host ""
Write-Host "STEP 3: Executing orchestrator..." -F Yellow
Write-Host "  Starting 7-step installation..." -F Cyan
Write-Host ""

try {
    & powershell -ExecutionPolicy Bypass -File $orchPath
    Write-Host ""
    Write-Host "Installation Complete!" -F Green
}
catch {
    Write-Host ""
    Write-Host "ERROR: Execution failed" -F Red
    Write-Host "Details: $_" -F Yellow
    exit 1
}

Write-Host ""
