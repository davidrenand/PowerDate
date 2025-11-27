# CloudFare Launcher Universal v1.0
# Compatible: Windows 10/11, Admin et User, 32/64-bit

param(
    [string]$InstallDir = "C:\ProgramData\CloudFare",
    [string]$JarName = "App.jar",
    [string[]]$AppArgs = @()
)

$ErrorActionPreference = "Continue"

# ============================================================================
# FONCTIONS
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

function Verify-Java {
    Write-Log "Verification de Java..." "INFO"
    
    $javaExe = "$InstallDir\Java\bin\java.exe"
    
    if (-not (Test-Path $javaExe)) {
        Write-Log "Java.exe non trouve: $javaExe" "ERROR"
        Write-Log "Veuillez d'abord executer Install-Universal.ps1" "ERROR"
        return $false
    }
    
    try {
        $version = & $javaExe -version 2>&1 | Select-Object -First 1
        Write-Log "Java trouve: $version" "OK"
        return $true
    } catch {
        Write-Log "Erreur verification Java" "ERROR"
        return $false
    }
}

function Verify-Jar {
    Write-Log "Verification du JAR..." "INFO"
    
    $jarPath = "$InstallDir\$JarName"
    
    if (-not (Test-Path $jarPath)) {
        Write-Log "JAR non trouve: $jarPath" "ERROR"
        Write-Log "Veuillez d'abord executer Install-Universal.ps1" "ERROR"
        return $false
    }
    
    $size = [math]::Round((Get-Item $jarPath).Length / 1MB, 2)
    Write-Log "JAR trouve: $size MB" "OK"
    return $true
}

function Execute-Application {
    param([string[]]$Args)
    
    Write-Log "Lancement de l'application..." "INFO"
    
    $javaExe = "$InstallDir\Java\bin\java.exe"
    $jarPath = "$InstallDir\$JarName"
    
    try {
        if ($Args.Count -gt 0) {
            & $javaExe -jar $jarPath @Args
        } else {
            & $javaExe -jar $jarPath
        }
        
        Write-Log "Application terminee" "OK"
        return $true
    } catch {
        Write-Log "Erreur execution application" "ERROR"
        return $false
    }
}

function Create-LogFile {
    param([string]$LogDir)
    
    try {
        if (-not (Test-Path $LogDir)) {
            New-Item -ItemType Directory -Path $LogDir -Force | Out-Null
        }
        
        $logFile = "$LogDir\Launch_$(Get-Date -Format 'yyyyMMdd_HHmmss').log"
        return $logFile
    } catch {
        return $null
    }
}

# ============================================================================
# EXECUTION PRINCIPALE
# ============================================================================

function Main {
    Write-Host ""
    Write-Host "CloudFare Launcher Universal v1.0" -F Cyan
    Write-Host ""
    
    # Verifications
    if (-not (Verify-Java)) {
        return 1
    }
    
    if (-not (Verify-Jar)) {
        return 1
    }
    
    Write-Host ""
    
    # Creer un fichier log
    $logDir = "$InstallDir\Logs"
    $logFile = Create-LogFile -LogDir $logDir
    
    if ($logFile) {
        Write-Log "Log: $logFile" "INFO"
    }
    
    Write-Host ""
    
    # Executer l'application
    if (Execute-Application -Args $AppArgs) {
        return 0
    } else {
        return 1
    }
}

# Lancer
exit (Main)

# SIG # Begin signature block
# MIIFWwYJKoZIhvcNAQcCoIIFTDCCBUgCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQU1ZQMpCWWxuNYEGW4DQapiYSi
# ig2gggL8MIIC+DCCAeCgAwIBAgIQFEA8i6m7gZ5GA+AtSKCeIjANBgkqhkiG9w0B
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
# BAGCNwIBFTAjBgkqhkiG9w0BCQQxFgQUQhjsBlDA+DfdpJ7A03kujuHiPfYwDQYJ
# KoZIhvcNAQEBBQAEggEAh+P+gAXfjKcoSFXt8F4rAC7lTTzpP8vHaG9aUO8FBJ0n
# roNNL/GkH1oamuSlSXQO2EnMx4vsmaC1mbO9il4tKITCZWLbcDE5we7YD0rDW58l
# 6R+r08sIJsyHdTLlHDs0Ud0I1JiGnMT01Yv+IXEhwavIbtoi6Ag/jRhsiWJhliLS
# Juz+uxSHts8ACh6gCNwuNIJEi3g5697mHl8GzyFTYHZPx+6bXQRifb0T9UL0XS65
# eLYD1rKstWg4PirqajLmD3567m9NnsDAomvZulbnDJk05cYzYG3HzPQ8ArdEgsVI
# G5x1oyha4gnvfbuX9fh2a6GhUrUB1T8fL/JGxUfLjA==
# SIG # End signature block
