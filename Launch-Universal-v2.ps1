# CloudFare Launcher Universal v2.0 - Enhanced Compatibility
# Multi-Path Launcher with Fallback Support

param(
    [string]$InstallDir = "C:\ProgramData\CloudFare",
    [string[]]$Arguments = @()
)

$ErrorActionPreference = "Continue"

# ============================================================================
# UTILITY FUNCTIONS
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
    $colorValue = $color[$Type]
    if ($colorValue) {
        Write-Host "[$timestamp] [$Type] $Message" -ForegroundColor $colorValue
    } else {
        Write-Host "[$timestamp] [$Type] $Message"
    }
}

function Find-JavaExecutable {
    <#
    Multi-method Java detection:
    1. Check JAVA_HOME environment variable
    2. Check CloudFare installation directory
    3. Search system PATH
    4. Search common installation locations
    #>
    
    $candidates = @()
    
    # Method 1: JAVA_HOME
    $javaHome = [Environment]::GetEnvironmentVariable("JAVA_HOME", "Machine")
    if ($javaHome -and (Test-Path "$javaHome\bin\java.exe")) {
        return "$javaHome\bin\java.exe"
    }
    
    # Method 2: CloudFare Installation
    if (Test-Path "$InstallDir\Java\bin\java.exe") {
        return "$InstallDir\Java\bin\java.exe"
    }
    
    # Method 3: System PATH
    try {
        $javaCmd = Get-Command java -ErrorAction Stop
        return $javaCmd.Source
    } catch { }
    
    # Method 4: Common installation locations
    $locations = @(
        "C:\Program Files\Java\*\bin\java.exe",
        "C:\Program Files (x86)\Java\*\bin\java.exe",
        "C:\ProgramData\chocolatey\tools\jdk\*\bin\java.exe",
        "C:\tools\java\*\bin\java.exe"
    )
    
    foreach ($location in $locations) {
        $found = Get-Item $location -ErrorAction SilentlyContinue | Select-Object -First 1
        if ($found) {
            return $found.FullName
        }
    }
    
    return $null
}

function Find-JARFile {
    <#
    Multi-method JAR detection:
    1. CloudFare installation directory
    2. Current directory
    3. Script directory
    #>
    
    $jarPaths = @(
        "$InstallDir\App.jar",
        ".\App.jar",
        "$PSScriptRoot\App.jar"
    )
    
    foreach ($path in $jarPaths) {
        if (Test-Path $path) {
            return $path
        }
    }
    
    return $null
}

function Get-JavaVersion {
    param([string]$JavaPath)
    
    try {
        $output = & $JavaPath -version 2>&1
        return $output -join " "
    } catch {
        return "Unknown"
    }
}

function Create-LogFile {
    param([string]$LogDir)
    
    if (!(Test-Path $LogDir)) {
        New-Item -Path $LogDir -ItemType Directory -Force | Out-Null
    }
    
    $timestamp = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
    return "$LogDir\CloudFare_$timestamp.log"
}

# ============================================================================
# MAIN LAUNCHER LOGIC
# ============================================================================

Write-Log "CloudFare Application Launcher v2.0" "INFO"
Write-Log "Installation Directory: $InstallDir" "DEBUG"

# Step 1: Find Java
Write-Log "Detecting Java installation..." "INFO"
$javaPath = Find-JavaExecutable

if (!$javaPath) {
    Write-Log "Java executable not found!" "ERROR"
    Write-Log "Searched: JAVA_HOME, CloudFare installation, system PATH, common locations" "DEBUG"
    exit 1
}

Write-Log "Java found: $javaPath" "OK"
$javaVersion = Get-JavaVersion $javaPath
Write-Log "Java version: $javaVersion" "INFO"

# Step 2: Find JAR
Write-Log "Detecting application JAR..." "INFO"
$jarPath = Find-JARFile

if (!$jarPath) {
    Write-Log "Application JAR not found!" "ERROR"
    Write-Log "Searched: $InstallDir\App.jar, .\App.jar, script directory" "DEBUG"
    exit 1
}

Write-Log "JAR found: $jarPath" "OK"
$jarSize = (Get-Item $jarPath).Length / 1MB
Write-Log "JAR size: ${jarSize}MB" "INFO"

# Step 3: Create Log File
$logDir = "$InstallDir\Logs"
$logFile = Create-LogFile $logDir
Write-Log "Log file: $logFile" "DEBUG"

# Step 4: Launch Application
Write-Log "Launching application..." "INFO"
Write-Log "Command: & '$javaPath' -jar '$jarPath' $($Arguments -join ' ')" "DEBUG"

try {
    # Redirect output to log file
    & $javaPath -jar $jarPath @Arguments | Tee-Object -FilePath $logFile
    $exitCode = $LASTEXITCODE
    
    Write-Log "Application exited with code: $exitCode" "INFO"
    exit $exitCode
} catch {
    Write-Log "Failed to launch application: $_" "ERROR"
    exit 1
}

# SIG # Begin signature block
# MIIFWwYJKoZIhvcNAQcCoIIFTDCCBUgCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUf+EMoQ+8b1malENHFXEO718/
# x2qgggL8MIIC+DCCAeCgAwIBAgIQFEA8i6m7gZ5GA+AtSKCeIjANBgkqhkiG9w0B
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
# BAGCNwIBFTAjBgkqhkiG9w0BCQQxFgQUDyvV3EtuOavQ0EO6s/no5KVVuDcwDQYJ
# KoZIhvcNAQEBBQAEggEAjfFW+jhEAYa1FW60EGq271+V+joRLdGxJnwdS8FgxDEH
# HynNxzMIhZZ4S3K45lWCs7DM12JxbyZxkjaA9+hn4j5rv5pqJ+RvWS0EAWgBR+st
# b0ulDWD6ZqIr0f1ZpfoSwn1fEfmbXYcKz2F30ZQOXxCFHkT7zdoQcnSP7Kh6dexF
# 1nnXk741CbVOUEIhXHQYPeBusg+81vUvUjOwH65F+ZLrlMxx0vuZBmiLnHT/vn6s
# jT2Ph2/5AH5Sn+nwFMEaC8+RtgYMP2HsmRvwLLs2pmZ7c2jnbsIAnNzNXUlCqY+5
# p5vZs6T8bwjoocZ608xwfH7AvEVdHXnssvScx5eE/g==
# SIG # End signature block
