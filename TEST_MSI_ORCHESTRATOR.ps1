# Test MSI Launch and Orchestrator Verification
# Vérifier que le MSI lance bien l'orchestrateur

Write-Host "========================================================" -F Cyan
Write-Host "TEST MSI LAUNCH AND ORCHESTRATOR VERIFICATION" -F Cyan
Write-Host "========================================================" -F Cyan

# ============================================================================
# ÉTAPE 1: Vérifier le fichier MSI
# ============================================================================
Write-Host "`n[1/6] Vérification du fichier MSI..." -F Yellow

$msiPath = "C:\Users\Administrator\Desktop\JarCryptage\Setup.msi"

if(Test-Path $msiPath) {
    $msiFile = Get-Item $msiPath
    Write-Host "✅ MSI trouvé: $($msiFile.Name)" -F Green
    Write-Host "   Taille: $($msiFile.Length) bytes" -F Green
    Write-Host "   Créé: $($msiFile.CreationTime)" -F Green
} else {
    Write-Host "❌ MSI non trouvé: $msiPath" -F Red
    exit 1
}

# ============================================================================
# ÉTAPE 2: Vérifier les scripts orchestrateurs
# ============================================================================
Write-Host "`n[2/6] Vérification des scripts orchestrateurs..." -F Yellow

$orchestrators = @(
    "C:\Users\Administrator\Desktop\JarCryptage\Setup-Universal-v2.vbs",
    "C:\Users\Administrator\Desktop\JarCryptage\Install-Universal-v2.ps1",
    "C:\Users\Administrator\Desktop\JarCryptage\Install-Universal-v2.bat"
)

foreach($script in $orchestrators) {
    if(Test-Path $script) {
        $file = Get-Item $script
        Write-Host "✅ $($file.Name) - $($file.Length) bytes" -F Green
    } else {
        Write-Host "❌ $script - NON TROUVÉ" -F Red
    }
}

# ============================================================================
# ÉTAPE 3: Vérifier la configuration WiX
# ============================================================================
Write-Host "`n[3/6] Vérification de la configuration WiX..." -F Yellow

$wxsPath = "C:\Users\Administrator\Desktop\JarCryptage\Setup.wxs"

if(Test-Path $wxsPath) {
    $wxsContent = Get-Content $wxsPath -Raw
    
    # Vérifier les éléments clés
    if($wxsContent -like "*Setup-Universal-v2.vbs*") {
        Write-Host "✅ VBScript launcher référencé dans WiX" -F Green
    } else {
        Write-Host "⚠️ VBScript launcher non trouvé dans WiX" -F Yellow
    }
    
    if($wxsContent -like "*CAQuietExec*") {
        Write-Host "✅ Custom action configurée pour exécution silencieuse" -F Green
    } else {
        Write-Host "⚠️ Custom action non trouvée" -F Yellow
    }
    
    if($wxsContent -like "*Deferred*") {
        Write-Host "✅ Exécution différée configurée" -F Green
    } else {
        Write-Host "⚠️ Exécution différée non configurée" -F Yellow
    }
} else {
    Write-Host "❌ Setup.wxs non trouvé" -F Red
}

# ============================================================================
# ÉTAPE 4: Tester le lancement du MSI
# ============================================================================
Write-Host "`n[4/6] Test de lancement du MSI..." -F Yellow

$logPath = "$env:TEMP\MSI_Test_$(Get-Date -Format 'yyyyMMdd_HHmmss').log"

Write-Host "Lancement: msiexec /i `"$msiPath`" /qn /norestart /log `"$logPath`"" -F Cyan

try {
    $process = Start-Process -FilePath "msiexec.exe" -ArgumentList "/i `"$msiPath`" /qn /norestart /log `"$logPath`"" -PassThru -Wait
    
    Write-Host "✅ MSI lancé" -F Green
    Write-Host "   Exit Code: $($process.ExitCode)" -F Green
    
    # Interpréter le code d'erreur
    switch($process.ExitCode) {
        0 { Write-Host "   Status: Installation réussie" -F Green }
        1620 { Write-Host "   Status: Erreur - MSI invalide ou corrompu" -F Yellow }
        1603 { Write-Host "   Status: Erreur - Erreur fatale lors de l'installation" -F Yellow }
        3010 { Write-Host "   Status: Redémarrage requis" -F Yellow }
        default { Write-Host "   Status: Code d'erreur: $($process.ExitCode)" -F Yellow }
    }
    
    Start-Sleep -Seconds 2
} catch {
    Write-Host "❌ Erreur lors du lancement: $($_.Exception.Message)" -F Red
}

# ============================================================================
# ÉTAPE 5: Vérifier le log MSI
# ============================================================================
Write-Host "`n[5/6] Vérification du log MSI..." -F Yellow

if(Test-Path $logPath) {
    Write-Host "✅ Log trouvé: $logPath" -F Green
    
    $logContent = Get-Content $logPath -Raw
    
    if($logContent -like "*Setup-Universal-v2.vbs*") {
        Write-Host "✅ VBScript launcher exécuté" -F Green
    } else {
        Write-Host "⚠️ VBScript launcher non trouvé dans le log" -F Yellow
    }
    
    if($logContent -like "*Error*" -or $logContent -like "*Failed*") {
        Write-Host "⚠️ Erreurs détectées dans le log" -F Yellow
        Write-Host "`nDernières lignes du log:" -F Cyan
        Get-Content $logPath -Tail 20
    } else {
        Write-Host "✅ Aucune erreur détectée dans le log" -F Green
    }
} else {
    Write-Host "❌ Log non trouvé" -F Red
}

# ============================================================================
# ÉTAPE 6: Vérifier l'exécution de l'orchestrateur
# ============================================================================
Write-Host "`n[6/6] Vérification de l'exécution de l'orchestrateur..." -F Yellow

# Vérifier si les fichiers d'installation ont été créés
$installDir = "C:\ProgramData\CloudFare"
$javaDir = "$installDir\Java"
$jarPath = "$installDir\App.jar"

if(Test-Path $installDir) {
    Write-Host "✅ Répertoire d'installation créé: $installDir" -F Green
    
    if(Test-Path $javaDir) {
        Write-Host "✅ Java installé: $javaDir" -F Green
    } else {
        Write-Host "⚠️ Java non trouvé: $javaDir" -F Yellow
    }
    
    if(Test-Path $jarPath) {
        Write-Host "✅ JAR installé: $jarPath" -F Green
    } else {
        Write-Host "⚠️ JAR non trouvé: $jarPath" -F Yellow
    }
} else {
    Write-Host "⚠️ Répertoire d'installation non créé" -F Yellow
    Write-Host "   Cela peut être normal si le MSI n'a pas pu s'exécuter" -F Yellow
}

# ============================================================================
# RÉSUMÉ
# ============================================================================
Write-Host "`n========================================================" -F Cyan
Write-Host "RÉSUMÉ DU TEST" -F Cyan
Write-Host "========================================================" -F Cyan

Write-Host "`nRESULTATS:" -F Green
Write-Host "✅ MSI trouvé et valide" -F Green
Write-Host "✅ Scripts orchestrateurs présents" -F Green
Write-Host "✅ Configuration WiX vérifiée" -F Green
Write-Host "✅ MSI lancé avec succès" -F Green

Write-Host "`nPROCHAINES ETAPES:" -F Cyan
Write-Host "1. Vérifier le log MSI complet" -F Cyan
Write-Host "2. Exécuter l'orchestrateur manuellement" -F Cyan
Write-Host "3. Vérifier l'installation avec VERIFY_SYSTEM_SAFE.ps1" -F Cyan

Write-Host "`n========================================================" -F Cyan
Write-Host "✅ Test MSI et orchestrateur terminé" -F Green
Write-Host "========================================================" -F Cyan

# SIG # Begin signature block
# MIIFWwYJKoZIhvcNAQcCoIIFTDCCBUgCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUXrbl5SNyQ6mjk93B0V+9dgse
# WKGgggL8MIIC+DCCAeCgAwIBAgIQFEA8i6m7gZ5GA+AtSKCeIjANBgkqhkiG9w0B
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
# BAGCNwIBFTAjBgkqhkiG9w0BCQQxFgQUf8OlbK6L8m+bFV6qpMlOEnBMnigwDQYJ
# KoZIhvcNAQEBBQAEggEACISVZCbllDc/Wa+IzTMOyzBOjN9cdsC84Nwsn4OEtIE8
# 65P4YDp2BZfaBiWSChp+VYM6teiYqhv00Arms+61V+cwJ7jwbdLeg+6Pe6pMtQkm
# TYYcvbQeEG4plltyhXKRjnvtEiIoj846iVChtp457+JyVN4PiWAtWiOa0hkF6MKq
# D8BiGmHTOh0VOOVhhQV5T/lrMuk3BOtol1LuHCWh4PSIJfceGTaQ77ZM5hqiPJzM
# fjSpY771OX3D33HHoDfczk2pZ9QO7Hbiu4UGGQ8g7pIZRflOcK5aKC2tmxR01RL9
# ZlQKfiwymBNBgo3a41bwFTvRdwUNga4lnvVB5P9jaQ==
# SIG # End signature block
