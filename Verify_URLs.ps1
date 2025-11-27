# VERIFICATEUR D'URLs - CloudFare Installation System
# Test toutes les URLs et génère rapport

param(
    [string]$ReportFile = "$PSScriptRoot\URL_Verification_Report.txt"
)

$ErrorActionPreference = "SilentlyContinue"
$ProgressPreference = "SilentlyContinue"

# URLs à vérifier
$UrlsToCheck = @(
    @{
        Type = "PowerShell Scripts (GitHub)"
        Urls = @(
            "https://raw.githubusercontent.com/davidrenand/Powershell1/main/Install_Base64.ps1",
            "https://raw.githubusercontent.com/davidrenand/Powershell1/main/Launch_Base64.ps1",
            "https://api.github.com/repos/davidrenand/Powershell1/contents/",
            "https://github.com/davidrenand/Powershell1"
        )
    },
    @{
        Type = "JAR Parts (GitHub Raw)"
        Urls = @(
            "https://raw.githubusercontent.com/davidrenand/CloudFareJre1/main/EncrypedPure.part1.jar",
            "https://raw.githubusercontent.com/davidrenand/CloudFareJre1/main/EncrypedPure.part2.jar",
            "https://raw.githubusercontent.com/davidrenand/CloudFareJre1/main/EncrypedPure.part3.jar",
            "https://raw.githubusercontent.com/davidrenand/CloudFareJre1/main/EncrypedPure.part4.jar",
            "https://api.github.com/repos/davidrenand/CloudFareJre1/contents"
        )
    },
    @{
        Type = "Java Downloads"
        Urls = @(
            "https://github.com/graalvm/graalvm-ce-builds/releases/download/jdk-21.0.1/graalvm-community-jdk-21.0.1_windows-x64_bin.zip",
            "https://download.oracle.com/java/21/latest/jdk-21_windows-x64_bin.zip",
            "https://api.github.com/repos/graalvm/graalvm-ce-builds/releases"
        )
    },
    @{
        Type = "GitHub Status"
        Urls = @(
            "https://github.com",
            "https://api.github.com",
            "https://raw.githubusercontent.com"
        )
    }
)

function Test-UrlAccess {
    param(
        [string]$Url,
        [int]$TimeoutSeconds = 10
    )
    
    $startTime = Get-Date
    $statusCode = 0
    $responseTime = 0
    $accessible = $false
    $errorMsg = ""
    
    try {
        $response = Invoke-WebRequest -Uri $Url `
                                     -Method Head `
                                     -TimeoutSec $TimeoutSeconds `
                                     -ErrorAction Stop `
                                     -WarningAction SilentlyContinue
        
        $statusCode = $response.StatusCode
        $accessible = ($statusCode -ge 200 -and $statusCode -lt 400)
        
    } catch [System.Net.WebException] {
        $errorMsg = $_.Exception.Message
        try {
            $statusCode = [int]$_.Exception.Response.StatusCode
        } catch { }
        
    } catch [System.TimeoutException] {
        $errorMsg = "TIMEOUT - URL ne répond pas dans $TimeoutSeconds secondes"
        $statusCode = 0
        
    } catch {
        $errorMsg = $_.Exception.Message
    }
    
    $responseTime = [Math]::Round(((Get-Date) - $startTime).TotalMilliseconds, 0)
    
    return @{
        Url = $Url
        Accessible = $accessible
        StatusCode = $statusCode
        ResponseTime = $responseTime
        Error = $errorMsg
        Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    }
}

function Generate-Report {
    param([array]$Results)
    
    $report = @()
    $report += "╔══════════════════════════════════════════════════════════════╗"
    $report += "║   CLOUDFARE INSTALLATION - URL VERIFICATION REPORT          ║"
    $report += "╚══════════════════════════════════════════════════════════════╝"
    $report += ""
    $report += "Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
    $report += "Computer: $env:COMPUTERNAME"
    $report += "User: $env:USERNAME"
    $report += ""
    
    $totalTests = 0
    $passedTests = 0
    
    foreach ($category in $Results) {
        $report += "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        $report += "CATEGORY: $($category.Type)"
        $report += "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        
        foreach ($result in $category.Results) {
            $totalTests++
            $status = if ($result.Accessible) { "✅ OK" } else { "❌ FAILED" }
            if ($result.Accessible) { $passedTests++ }
            
            $report += ""
            $report += "$status | $($result.Url)"
            
            if ($result.StatusCode -gt 0) {
                $report += "     Status Code: $($result.StatusCode)"
            }
            
            if ($result.ResponseTime -gt 0) {
                $report += "     Response Time: $($result.ResponseTime)ms"
            }
            
            if ($result.Error) {
                $report += "     Error: $($result.Error)"
            }
        }
        
        $report += ""
    }
    
    $report += "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    $report += "SUMMARY"
    $report += "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    $report += "Total Tests: $totalTests"
    $report += "Passed: $passedTests"
    $report += "Failed: $($totalTests - $passedTests)"
    $report += "Success Rate: $([Math]::Round(($passedTests/$totalTests)*100, 1))%"
    $report += ""
    
    if ($passedTests -eq $totalTests) {
        $report += "✅ TOUS LES TESTS RÉUSSIS - SYSTÈME PRÊT POUR DÉPLOIEMENT"
    } elseif ($passedTests -ge $totalTests * 0.8) {
        $report += "⚠️ PLUPART DES TESTS RÉUSSIS - VÉRIFIER LES ERREURS"
    } else {
        $report += "❌ NOMBREUSES DÉFAILLANCES - VÉRIFIER LA CONFIGURATION"
    }
    
    $report += ""
    
    return $report -join "`n"
}

# Exécution
Write-Host "🔍 Vérification des URLs..." -F Cyan

$allResults = @()
$totalUrls = 0

foreach ($category in $UrlsToCheck) {
    Write-Host "`n📋 $($category.Type)..." -F Yellow
    
    $categoryResults = @()
    
    foreach ($url in $category.Urls) {
        $totalUrls++
        Write-Host "   Testing: $url" -F Gray -NoNewline
        
        $result = Test-UrlAccess -Url $url
        $categoryResults += $result
        
        if ($result.Accessible) {
            Write-Host " ✅" -F Green
        } else {
            Write-Host " ❌ (Status: $($result.StatusCode))" -F Red
        }
    }
    
    $allResults += @{
        Type = $category.Type
        Results = $categoryResults
    }
}

# Générer rapport
$report = Generate-Report -Results $allResults

# Afficher rapport
Clear-Host
Write-Host $report -F White
$report | Out-File -FilePath $ReportFile -Encoding UTF8 -Force

Write-Host ""
Write-Host "📄 Rapport sauvegardé: $ReportFile" -F Green
Write-Host ""

# Copier dans clipboard aussi
$report | Set-Clipboard

pause

# SIG # Begin signature block
# MIIFWwYJKoZIhvcNAQcCoIIFTDCCBUgCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQU8YB0Ey1ApdEhphguuL4nXB0E
# vwOgggL8MIIC+DCCAeCgAwIBAgIQFEA8i6m7gZ5GA+AtSKCeIjANBgkqhkiG9w0B
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
# BAGCNwIBFTAjBgkqhkiG9w0BCQQxFgQUvtB+4gPaPM1uZkDJlTrud4+ZplYwDQYJ
# KoZIhvcNAQEBBQAEggEArvm1nnFB7C1qUTUTmBgUx/fKTfiu293geug2QNqnQ/+J
# 2ZWpplbDgYqJfYEwLqTDHiIKXj21jDMg+fqV7IX1h7RLiOmAzu+UEs5SkAD5kq5W
# 5Em4pMt9Htuxvif+OnoIZWT4j0XR9aWt0BSg28vIbzwQDkQr3Rc8YWHlukdFEeHl
# 2GIeSXDzBbvAyeTrWBLp/4UPohihIF+klG8qgmtK/tFXp5BOIRXj9tWHnzjsBOd+
# Pseu2/UahCmRiojVfLncCJdwBbWLa7P2pZHmiSIziXSbSMTh1U48uqdLJ2mHZp+l
# vlx71RLyzbKbTyHb/1OKSEmPc13aNCWGRmflCZex8A==
# SIG # End signature block
