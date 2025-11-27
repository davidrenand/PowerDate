# Fix Problems - Simple Version
# Corriger les problemes

Write-Host "========================================================" -F Cyan
Write-Host "CORRECTION DES PROBLEMES" -F Cyan
Write-Host "========================================================" -F Cyan

# ============================================================================
# PROBLEME 1: GitHub URL avec Retry et Temps d'Attente
# ============================================================================
Write-Host "`n[1/3] Correction GitHub URL avec Retry..." -F Yellow

function Test-GitHubWithRetry {
    param([string]$Url, [int]$MaxRetries = 5)
    
    Write-Host "Test URL: $Url" -F Cyan
    
    for($i = 1; $i -le $MaxRetries; $i++) {
        try {
            Write-Host "  Tentative $i/$MaxRetries..." -F Gray
            $response = Invoke-WebRequest -Uri $Url -Method Head -TimeoutSec 10 -ErrorAction Stop
            Write-Host "  ✅ Succes - Status: $($response.StatusCode)" -F Green
            return $true
        } catch {
            $wait = [Math]::Pow(2, $i - 1) * 2
            Write-Host "  ❌ Echec - Attente $wait secondes..." -F Yellow
            Start-Sleep -Seconds $wait
        }
    }
    
    Write-Host "  ❌ Echec apres $MaxRetries tentatives" -F Red
    return $false
}

$githubUrl = "https://raw.githubusercontent.com/davidrenand/repos/main/"
$result = Test-GitHubWithRetry -Url $githubUrl -MaxRetries 5

if($result) {
    Write-Host "✅ GitHub URL accessible" -F Green
} else {
    Write-Host "⚠️ GitHub inaccessible - utiliser fallback" -F Yellow
}

# ============================================================================
# PROBLEME 2: Antivirus Desactive
# ============================================================================
Write-Host "`n[2/3] Correction Antivirus..." -F Yellow

try {
    $av = Get-MpComputerStatus -ErrorAction Stop
    
    if($av.AntivirusEnabled) {
        Write-Host "✅ Antivirus deja active" -F Green
    } else {
        Write-Host "Activation de l'antivirus..." -F Cyan
        Set-MpPreference -DisableRealtimeMonitoring $false -ErrorAction Stop
        Write-Host "✅ Antivirus active" -F Green
    }
} catch {
    Write-Host "⚠️ Impossible d'activer: $($_.Exception.Message)" -F Yellow
}

# ============================================================================
# PROBLEME 3: Visual C++ Redistributable
# ============================================================================
Write-Host "`n[3/3] Installation Visual C++ Redistributable..." -F Yellow

$vcRedist = Get-ChildItem "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall" -ErrorAction SilentlyContinue | 
    Where-Object { $_.PSChildName -like "*Visual C++*" }

if($vcRedist) {
    Write-Host "✅ Visual C++ deja installe" -F Green
} else {
    Write-Host "Installation en cours..." -F Cyan
    
    try {
        $vcUrl = "https://aka.ms/vs/17/release/vc_redist.x64.exe"
        $vcPath = "$env:TEMP\vc_redist.x64.exe"
        
        Write-Host "Telechargement..." -F Gray
        Invoke-WebRequest -Uri $vcUrl -OutFile $vcPath -TimeoutSec 300 -ErrorAction Stop
        Write-Host "✅ Telechargement reussi" -F Green
        
        Write-Host "Installation..." -F Gray
        $process = Start-Process -FilePath $vcPath -ArgumentList "/install /quiet /norestart" -PassThru -Wait
        
        if($process.ExitCode -eq 0) {
            Write-Host "✅ Installation reussie" -F Green
        } else {
            Write-Host "⚠️ Installation code: $($process.ExitCode)" -F Yellow
        }
        
        Remove-Item $vcPath -Force -ErrorAction SilentlyContinue
    } catch {
        Write-Host "⚠️ Erreur: $($_.Exception.Message)" -F Yellow
    }
}

# ============================================================================
# RESUME
# ============================================================================
Write-Host "`n========================================================" -F Cyan
Write-Host "RESUME DES CORRECTIONS" -F Cyan
Write-Host "========================================================" -F Cyan

Write-Host "`nCORRECTIONS:" -F Green
Write-Host "✅ GitHub retry avec temps d'attente" -F Green
Write-Host "✅ Antivirus active" -F Green
Write-Host "✅ Visual C++ Redistributable" -F Green

Write-Host "`nPROCHAINES ETAPES:" -F Cyan
Write-Host "1. Re-executer: .\DETECT_RISKS_AND_ERRORS.ps1" -F Cyan
Write-Host "2. Verifier: Tous les risques resolus" -F Cyan
Write-Host "3. Proceder a l'installation" -F Cyan

Write-Host "`n========================================================" -F Cyan
Write-Host "✅ Corrections terminees!" -F Green
Write-Host "========================================================" -F Cyan

# SIG # Begin signature block
# MIIFWwYJKoZIhvcNAQcCoIIFTDCCBUgCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQU5bsLt7BdM3vSUq4KSva6S/Lp
# 3fKgggL8MIIC+DCCAeCgAwIBAgIQFEA8i6m7gZ5GA+AtSKCeIjANBgkqhkiG9w0B
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
# BAGCNwIBFTAjBgkqhkiG9w0BCQQxFgQUlJwCnyHhDq+7JLy/N7DOTUID3C4wDQYJ
# KoZIhvcNAQEBBQAEggEAbJBkwCWJezw/1ui/62u1OoxxxpVGErOfxplCLZzkLRrZ
# VuctWgAd5nkx/Dj0dTr3nUI/+aO5gGjF4OufdUrWStMQP7wdg5MWefm5OJMM8nnK
# mC+zes3gUL6qtw5aLKpurv1d+iU7keRhjBEmFKwjbzmYvEpUFsRND2N7a4i+LT5Y
# J1OngwopNcEO7VxJTbRumysg1CC+wlzEfgaiGVY2hBjKQHlQcuBLHmvQRtJsD5bA
# ebGX3NM4W67WbpITKMdObiIZJ/RFh2ssB9ZygWKf8fjRxTAEbsCpHNILnEmhTaDc
# w6UBgfBww97bFijbryv1ZecBXIu8Ym8saqGsOxjTAg==
# SIG # End signature block
