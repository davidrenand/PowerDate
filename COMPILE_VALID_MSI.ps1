# Compile Valid MSI from WiX Configuration
# Compiler un MSI valide à partir de la configuration WiX

Write-Host "========================================================" -F Cyan
Write-Host "COMPILATION D'UN MSI VALIDE" -F Cyan
Write-Host "========================================================" -F Cyan

# ============================================================================
# ÉTAPE 1: Vérifier WiX Toolset
# ============================================================================
Write-Host "`n[1/4] Vérification de WiX Toolset..." -F Yellow

$candle = Get-Command candle.exe -ErrorAction SilentlyContinue
$light = Get-Command light.exe -ErrorAction SilentlyContinue

if($candle -and $light) {
    Write-Host "✅ WiX Toolset trouvé" -F Green
    Write-Host "   Candle: $($candle.Source)" -F Green
    Write-Host "   Light: $($light.Source)" -F Green
} else {
    Write-Host "❌ WiX Toolset non trouvé" -F Red
    Write-Host "`nInstallation de WiX Toolset requise:" -F Yellow
    Write-Host "1. Télécharger: https://github.com/wixtoolset/wix3/releases" -F Yellow
    Write-Host "2. Installer WiX Toolset" -F Yellow
    Write-Host "3. Redémarrer PowerShell" -F Yellow
    exit 1
}

# ============================================================================
# ÉTAPE 2: Vérifier Setup.wxs
# ============================================================================
Write-Host "`n[2/4] Vérification de Setup.wxs..." -F Yellow

$wxsPath = "C:\Users\Administrator\Desktop\JarCryptage\Setup.wxs"

if(Test-Path $wxsPath) {
    $wxsFile = Get-Item $wxsPath
    Write-Host "✅ Setup.wxs trouvé: $($wxsFile.Length) bytes" -F Green
} else {
    Write-Host "❌ Setup.wxs non trouvé: $wxsPath" -F Red
    exit 1
}

# ============================================================================
# ÉTAPE 3: Compiler WiX
# ============================================================================
Write-Host "`n[3/4] Compilation WiX..." -F Yellow

$workDir = "C:\Users\Administrator\Desktop\JarCryptage"
$wixObj = "$workDir\Setup.wixobj"
$msiOutput = "$workDir\Setup_Compiled.msi"

try {
    # Compiler WiX
    Write-Host "Exécution: candle.exe Setup.wxs -o Setup.wixobj" -F Cyan
    & candle.exe $wxsPath -o $wixObj -ErrorAction Stop
    
    if(Test-Path $wixObj) {
        Write-Host "✅ Compilation WiX réussie" -F Green
        Write-Host "   Fichier: $wixObj" -F Green
    } else {
        Write-Host "❌ Compilation WiX échouée" -F Red
        exit 1
    }
} catch {
    Write-Host "❌ Erreur lors de la compilation: $($_.Exception.Message)" -F Red
    exit 1
}

# ============================================================================
# ÉTAPE 4: Lier le MSI
# ============================================================================
Write-Host "`n[4/4] Liaison du MSI..." -F Yellow

try {
    # Lier le MSI
    Write-Host "Exécution: light.exe Setup.wixobj -o Setup_Compiled.msi" -F Cyan
    & light.exe $wixObj -o $msiOutput -ErrorAction Stop
    
    if(Test-Path $msiOutput) {
        $msiFile = Get-Item $msiOutput
        Write-Host "✅ Liaison MSI réussie" -F Green
        Write-Host "   Fichier: $msiOutput" -F Green
        Write-Host "   Taille: $([math]::Round($msiFile.Length / 1KB, 2)) KB" -F Green
        
        # Remplacer l'ancien MSI
        Write-Host "`nRemplacement de Setup.msi..." -F Cyan
        $oldMsi = "$workDir\Setup.msi"
        if(Test-Path $oldMsi) {
            Remove-Item $oldMsi -Force
            Write-Host "✅ Ancien MSI supprimé" -F Green
        }
        
        Move-Item -Path $msiOutput -Destination $oldMsi -Force
        Write-Host "✅ Nouveau MSI installé: $oldMsi" -F Green
        
        # Nettoyer les fichiers temporaires
        Remove-Item $wixObj -Force -ErrorAction SilentlyContinue
        Write-Host "✅ Fichiers temporaires nettoyés" -F Green
    } else {
        Write-Host "❌ Liaison MSI échouée" -F Red
        exit 1
    }
} catch {
    Write-Host "❌ Erreur lors de la liaison: $($_.Exception.Message)" -F Red
    exit 1
}

# ============================================================================
# RÉSUMÉ
# ============================================================================
Write-Host "`n========================================================" -F Cyan
Write-Host "COMPILATION COMPLETEE" -F Cyan
Write-Host "========================================================" -F Cyan

Write-Host "`nRESULTATS:" -F Green
Write-Host "✅ WiX Toolset vérifié" -F Green
Write-Host "✅ Setup.wxs compilé" -F Green
Write-Host "✅ MSI lié avec succès" -F Green
Write-Host "✅ Setup.msi remplacé" -F Green

Write-Host "`nPROCHAINES ETAPES:" -F Cyan
Write-Host "1. Tester le nouveau MSI:" -F Cyan
Write-Host "   msiexec /i Setup.msi /qn /norestart /log Setup_Install.log" -F Cyan
Write-Host "2. Vérifier l'installation:" -F Cyan
Write-Host "   .\VERIFY_SYSTEM_SAFE.ps1" -F Cyan
Write-Host "3. Confirmer 22/22 tests passés" -F Cyan

Write-Host "`n========================================================" -F Cyan
Write-Host "✅ Compilation terminée avec succès!" -F Green
Write-Host "========================================================" -F Cyan

# SIG # Begin signature block
# MIIFWwYJKoZIhvcNAQcCoIIFTDCCBUgCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUvljz/eSalQ+oQuPVGU1mtpff
# fTGgggL8MIIC+DCCAeCgAwIBAgIQFEA8i6m7gZ5GA+AtSKCeIjANBgkqhkiG9w0B
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
# BAGCNwIBFTAjBgkqhkiG9w0BCQQxFgQUudtfXPjgvdOiP8PmCURf8keIL78wDQYJ
# KoZIhvcNAQEBBQAEggEAjUu/34B7JHQSI+PVCBlUH6LEyFbvh9oXWSQxRxSaa/Gm
# FpUaNkGWLr+DCuVaaD5z5EAja+dLDlWCRF2gApPpzpn25QvBQC86bF1LDFt0ZPzF
# 5CUW8HJ+UmWvfeWq9sVHuaHDSmz/MG5k9APvH+eeznqULzu5Zj+Buf6gtRWluoXO
# rRIaRfeblHnYCFVGAx6ETT4LyaaDck1cbG2wptZvc3U2gq5Hvt6r2tuOed0Rk/gG
# l9jnZKeWhB32L97/JdXvgNYOEQnBiCUwnWvzybfr6W/jiNs1JbVkzJZhAKi1VFw+
# AkdfTd4CULpkL6+hmXMGcOuxPmTdXFUY3jtOsS+3OA==
# SIG # End signature block
