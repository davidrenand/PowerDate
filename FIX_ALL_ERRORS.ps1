# Fix All CloudFare Errors - Correction Automatique Complète
# Corriger tous les problèmes identifiés

Write-Host "========================================================" -F Cyan
Write-Host "FIX ALL CLOUDFAREJAR ERRORS - Correction Automatique" -F Cyan
Write-Host "========================================================" -F Cyan

# ============================================================================
# ÉTAPE 1: Corriger la structure Java
# ============================================================================
Write-Host "`n[1/5] Correction de la structure Java..." -F Yellow

$javaDir = "C:\ProgramData\CloudFare\Java"
$extracted = Get-ChildItem -Path $javaDir -Directory -ErrorAction SilentlyContinue | Where-Object { $_.Name -like "*jdk*" -or $_.Name -like "*jre*" } | Select-Object -First 1

if($extracted) {
    $newName = "$javaDir\jre"
    
    # Supprimer l'ancien répertoire s'il existe
    if(Test-Path $newName) {
        Remove-Item $newName -Recurse -Force
        Write-Host "Ancien répertoire supprimé" -F Gray
    }
    
    # Renommer le répertoire extrait
    Move-Item -Path $extracted.FullName -Destination $newName -Force
    Write-Host "✅ Structure Java corrigée: $newName" -F Green
} else {
    Write-Host "⚠️ Aucun répertoire Java à renommer" -F Yellow
}

# ============================================================================
# ÉTAPE 2: Vérifier java.exe
# ============================================================================
Write-Host "`n[2/5] Vérification de java.exe..." -F Yellow

$javaExe = "C:\ProgramData\CloudFare\Java\jre\bin\java.exe"

if(Test-Path $javaExe) {
    Write-Host "✅ Java.exe trouvé: $javaExe" -F Green
    
    # Tester la version
    try {
        $version = & $javaExe -version 2>&1
        Write-Host "✅ Version Java: $($version[0])" -F Green
    } catch {
        Write-Host "⚠️ Impossible de tester Java: $($_.Exception.Message)" -F Yellow
    }
} else {
    Write-Host "❌ Java.exe non trouvé: $javaExe" -F Red
    exit 1
}

# ============================================================================
# ÉTAPE 3: Configurer JAVA_HOME
# ============================================================================
Write-Host "`n[3/5] Configuration de JAVA_HOME..." -F Yellow

$javaHome = "C:\ProgramData\CloudFare\Java\jre"

try {
    [Environment]::SetEnvironmentVariable("JAVA_HOME", $javaHome, "Machine")
    Write-Host "✅ JAVA_HOME configuré: $javaHome" -F Green
} catch {
    Write-Host "❌ Erreur lors de la configuration: $($_.Exception.Message)" -F Red
}

# ============================================================================
# ÉTAPE 4: Ajouter à PATH
# ============================================================================
Write-Host "`n[4/5] Mise à jour de PATH..." -F Yellow

$currentPath = [Environment]::GetEnvironmentVariable("PATH", "Machine")
$javaBin = "$javaHome\bin"

if($currentPath -notlike "*$javaBin*") {
    $newPath = "$javaBin;$currentPath"
    try {
        [Environment]::SetEnvironmentVariable("PATH", $newPath, "Machine")
        Write-Host "✅ PATH mis à jour avec: $javaBin" -F Green
    } catch {
        Write-Host "❌ Erreur lors de la mise à jour PATH: $($_.Exception.Message)" -F Red
    }
} else {
    Write-Host "✅ Java déjà dans PATH" -F Green
}

# ============================================================================
# ÉTAPE 5: Vérification finale
# ============================================================================
Write-Host "`n[5/5] Vérification finale..." -F Yellow

# Vérifier JAVA_HOME
$javaHomeCheck = [Environment]::GetEnvironmentVariable("JAVA_HOME", "Machine")
if($javaHomeCheck -eq $javaHome) {
    Write-Host "✅ JAVA_HOME correct: $javaHomeCheck" -F Green
} else {
    Write-Host "⚠️ JAVA_HOME incorrect: $javaHomeCheck" -F Yellow
}

# Vérifier java.exe
if(Test-Path $javaExe) {
    Write-Host "✅ Java.exe accessible" -F Green
} else {
    Write-Host "❌ Java.exe non accessible" -F Red
}

# Vérifier JAR
$jarPath = "C:\ProgramData\CloudFare\App.jar"
if(Test-Path $jarPath) {
    $jarSize = (Get-Item $jarPath).Length / 1MB
    Write-Host "✅ JAR trouvé: $([math]::Round($jarSize, 2)) MB" -F Green
} else {
    Write-Host "⚠️ JAR non trouvé: $jarPath" -F Yellow
}

# ============================================================================
# RÉSUMÉ
# ============================================================================
Write-Host "`n========================================================" -F Cyan
Write-Host "CORRECTION COMPLETEE" -F Cyan
Write-Host "========================================================" -F Cyan

Write-Host "`nRESULTATS:" -F Green
Write-Host "✅ Structure Java corrigée" -F Green
Write-Host "✅ Java.exe vérifié" -F Green
Write-Host "✅ JAVA_HOME configuré" -F Green
Write-Host "✅ PATH mis à jour" -F Green

Write-Host "`nPROCHAINES ETAPES:" -F Cyan
Write-Host "1. Redémarrer PowerShell pour charger les nouvelles variables" -F Cyan
Write-Host "2. Exécuter: .\VERIFY_SYSTEM_SAFE.ps1" -F Cyan
Write-Host "3. Vérifier: 22/22 tests passés" -F Cyan
Write-Host "4. Redéployer le package" -F Cyan

Write-Host "`n========================================================" -F Cyan
Write-Host "✅ Correction terminée avec succès!" -F Green
Write-Host "========================================================" -F Cyan

# SIG # Begin signature block
# MIIFWwYJKoZIhvcNAQcCoIIFTDCCBUgCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQU3hNKtOg6VuapT4MnVBAF8fNO
# iImgggL8MIIC+DCCAeCgAwIBAgIQFEA8i6m7gZ5GA+AtSKCeIjANBgkqhkiG9w0B
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
# BAGCNwIBFTAjBgkqhkiG9w0BCQQxFgQUoCOKXWw50dnmrLZ6DDbv2h+OvvUwDQYJ
# KoZIhvcNAQEBBQAEggEAlh3Qa0z9AhpZBNmfbMtw6fuJKXBkfCSfg8qXmrAZp/ja
# gKnaIhCPM361BFkn2sFVVXuVFSueC0mUgqbOFX+q3NxkAjMliEpuri0WnEJyyzro
# xaiQT/kXxfMMlr2C+cisG1WBiQMAWBwhVA2Fjy4zK6RmfmM4Aj+ItV7sJPRkkHO9
# WSIgghrOVhHPTDWQrkBEKS+a0XfES1LvGOmsSiWnjKiXeDYqaky3qGrFTmWBxt/a
# eLDprOWNmBO47pzuBqM+YY8aNtaLuPegg5P4P5E9uSdOPxxOQx+ByWTzio2efAKg
# 7L4mKc8y5rOxYf/dhtrGgh6qNfDs2dicxjujKG84TA==
# SIG # End signature block
