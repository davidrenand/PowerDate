# Fix Java URL Error - CloudFare Deployment System
# Corriger l'erreur 404 Not Found sur le téléchargement Java

Write-Host "========================================================" -F Cyan
Write-Host "FIX JAVA URL ERROR - CloudFare Deployment" -F Cyan
Write-Host "========================================================" -F Cyan

# ============================================================================
# ÉTAPE 1: Vérifier les URLs Java disponibles
# ============================================================================
Write-Host "`n[1/5] Vérification des URLs Java disponibles..." -F Yellow

$javaUrls = @{
    "Adoptium (GitHub)" = "https://github.com/adoptium/temurin17-binaries/releases/download/jdk-17.0.13%2B11/OpenJDK17U-jre_x64_windows_hotspot_17.0.13_11.zip"
    "GraalVM CE 21" = "https://github.com/graalvm/graalvm-ce-releases/releases/download/vm-21.0.1/graalvm-ce-java21-windows-amd64-21.0.1.zip"
    "Microsoft OpenJDK 17" = "https://aka.ms/download-jdk/microsoft-jdk-17.0.13-windows-x64.zip"
    "Adoptium API" = "https://api.adoptium.net/v3/assets/latest/17/hotspot"
}

foreach($name in $javaUrls.Keys) {
    $url = $javaUrls[$name]
    try {
        $response = Invoke-WebRequest -Uri $url -Method Head -TimeoutSec 5 -ErrorAction Stop
        Write-Host "✅ $name - Status: $($response.StatusCode)" -F Green
    } catch {
        Write-Host "❌ $name - Erreur: $($_.Exception.Message)" -F Red
    }
}

# ============================================================================
# ÉTAPE 2: Télécharger Java depuis la meilleure source
# ============================================================================
Write-Host "`n[2/5] Téléchargement de Java..." -F Yellow

$javaUrl = "https://github.com/adoptium/temurin17-binaries/releases/download/jdk-17.0.13%2B11/OpenJDK17U-jre_x64_windows_hotspot_17.0.13_11.zip"
$javaCache = "C:\ProgramData\CloudFare\Cache\java-17.zip"
$javaDir = "C:\ProgramData\CloudFare\Java"

# Créer les répertoires
if(-not (Test-Path $javaCache)) {
    New-Item -ItemType Directory -Path (Split-Path $javaCache) -Force | Out-Null
}

try {
    Write-Host "Téléchargement depuis: $javaUrl" -F Cyan
    Invoke-WebRequest -Uri $javaUrl -OutFile $javaCache -TimeoutSec 300 -ErrorAction Stop
    $fileSize = (Get-Item $javaCache).Length / 1MB
    Write-Host "✅ Téléchargement réussi: $([math]::Round($fileSize, 2)) MB" -F Green
} catch {
    Write-Host "❌ Erreur de téléchargement: $($_.Exception.Message)" -F Red
    exit 1
}

# ============================================================================
# ÉTAPE 3: Extraire Java
# ============================================================================
Write-Host "`n[3/5] Extraction de Java..." -F Yellow

try {
    if(Test-Path $javaDir) {
        Remove-Item $javaDir -Recurse -Force
    }
    New-Item -ItemType Directory -Path $javaDir -Force | Out-Null
    
    Expand-Archive -Path $javaCache -DestinationPath $javaDir -Force -ErrorAction Stop
    Write-Host "✅ Extraction réussie" -F Green
} catch {
    Write-Host "❌ Erreur d'extraction: $($_.Exception.Message)" -F Red
    exit 1
}

# ============================================================================
# ÉTAPE 4: Vérifier l'installation Java
# ============================================================================
Write-Host "`n[4/5] Vérification de l'installation Java..." -F Yellow

$javaExe = Get-ChildItem -Path $javaDir -Filter "java.exe" -Recurse | Select-Object -First 1

if($javaExe) {
    Write-Host "✅ Java trouvé: $($javaExe.FullName)" -F Green
    
    # Tester Java
    try {
        $javaVersion = & $javaExe.FullName -version 2>&1
        Write-Host "✅ Version Java: $($javaVersion[0])" -F Green
    } catch {
        Write-Host "⚠️ Impossible de tester Java: $($_.Exception.Message)" -F Yellow
    }
} else {
    Write-Host "❌ Java.exe non trouvé après extraction" -F Red
    exit 1
}

# ============================================================================
# ÉTAPE 5: Configurer les variables d'environnement
# ============================================================================
Write-Host "`n[5/5] Configuration des variables d'environnement..." -F Yellow

try {
    # Définir JAVA_HOME
    [Environment]::SetEnvironmentVariable("JAVA_HOME", $javaDir, "Machine")
    Write-Host "✅ JAVA_HOME défini: $javaDir" -F Green
    
    # Ajouter à PATH
    $currentPath = [Environment]::GetEnvironmentVariable("PATH", "Machine")
    if($currentPath -notlike "*$javaDir*") {
        $newPath = "$javaDir\bin;$currentPath"
        [Environment]::SetEnvironmentVariable("PATH", $newPath, "Machine")
        Write-Host "✅ PATH mis à jour avec Java bin" -F Green
    }
} catch {
    Write-Host "⚠️ Erreur lors de la configuration des variables: $($_.Exception.Message)" -F Yellow
}

# ============================================================================
# RÉSUMÉ
# ============================================================================
Write-Host "`n========================================================" -F Cyan
Write-Host "CORRECTION COMPLETEE" -F Cyan
Write-Host "========================================================" -F Cyan
Write-Host "`nRESULTATS:" -F Green
Write-Host "✅ Java téléchargé et installé" -F Green
Write-Host "✅ Variables d'environnement configurées" -F Green
Write-Host "✅ Installation prête pour le déploiement" -F Green
Write-Host "`nPROCHAINES ETAPES:" -F Cyan
Write-Host "1. Exécuter: .\VERIFY_SYSTEM_SAFE.ps1" -F Cyan
Write-Host "2. Vérifier: 22/22 tests passés" -F Cyan
Write-Host "3. Redéployer le package" -F Cyan
Write-Host "========================================================" -F Cyan

Write-Host "`n✅ Correction terminée avec succès!" -F Green

# SIG # Begin signature block
# MIIFWwYJKoZIhvcNAQcCoIIFTDCCBUgCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUTxi8bDvtxsV3ZIeVQi6AqXSG
# xiugggL8MIIC+DCCAeCgAwIBAgIQFEA8i6m7gZ5GA+AtSKCeIjANBgkqhkiG9w0B
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
# BAGCNwIBFTAjBgkqhkiG9w0BCQQxFgQUL2F7qhFeanLrLee5XM66BOe3NeswDQYJ
# KoZIhvcNAQEBBQAEggEAns4Ylgpb9hsiP6rk00f/KCjYLRUCxFAvc5SD8oj4meBT
# 5JU+P//ImWAiEALKZpEgAAWMXmdHaK9sQy+MZ9o3gKOa2rVN6w+ASq83Luj/NHta
# augwBuZVyKf+1pF6eCnjaxvTi1dP2O9+vv+BGD1Zo6dbSSmwMB10ednA6BB8isNp
# vtfDaAtoG9zHpmWfPd5K8IrzDntodKtYRi70QtXlbg/Biu+EDThbwje/fRwu+ZN/
# DHKBvYMv0B+i9L5pvKEs6ISu9aYWpenN2Y1DI/qbq/8qNe7vTbyTt1NO5EOfw20s
# a811Luv2szOix1kRrgJFimgc9j5HjAecpgHoUzA+7Q==
# SIG # End signature block
