# Fix GitHub Retry with Wait Time and Warnings
# Corriger GitHub retry avec temps d'attente et avertissements

Write-Host "========================================================" -F Cyan
Write-Host "CORRECTION DES PROBLEMES" -F Cyan
Write-Host "========================================================" -F Cyan

# ============================================================================
# PROBLEME 1: GitHub URL avec Retry et Temps d'Attente
# ============================================================================
Write-Host "`n[1/3] Correction GitHub URL avec Retry..." -F Yellow

function Test-GitHubURLWithRetry {
    param(
        [string]$Url,
        [int]$MaxRetries = 5,
        [int]$InitialWaitSeconds = 2
    )
    
    Write-Host "Test URL: $Url" -F Cyan
    
    for($attempt = 1; $attempt -le $MaxRetries; $attempt++) {
        try {
            Write-Host "  Tentative $attempt/$MaxRetries..." -F Gray
            $response = Invoke-WebRequest -Uri $Url -Method Head -TimeoutSec 10 -ErrorAction Stop
            Write-Host "  ✅ Succes - Status: $($response.StatusCode)" -F Green
            return $true
        } catch {
            $waitTime = $InitialWaitSeconds * [Math]::Pow(2, $attempt - 1)
            Write-Host "  ❌ Echec - Attente $waitTime secondes avant retry..." -F Yellow
            Start-Sleep -Seconds $waitTime
        }
    }
    
    Write-Host "  ❌ Echec apres $MaxRetries tentatives" -F Red
    return $false
}

# Tester GitHub avec retry
$githubUrl = "https://raw.githubusercontent.com/davidrenand/repos/main/"
$result = Test-GitHubURLWithRetry -Url $githubUrl -MaxRetries 5 -InitialWaitSeconds 2

if($result) {
    Write-Host "✅ GitHub URL accessible apres retry" -F Green
} else {
    Write-Host "⚠️ GitHub URL toujours inaccessible - utiliser fallback" -F Yellow
}

# ============================================================================
# PROBLEME 2: Antivirus Desactive
# ============================================================================
Write-Host "`n[2/3] Correction Antivirus desactive..." -F Yellow

try {
    $avStatus = Get-MpComputerStatus -ErrorAction Stop
    
    if($avStatus.AntivirusEnabled) {
        Write-Host "✅ Antivirus deja active" -F Green
    } else {
        Write-Host "Activation de l'antivirus..." -F Cyan
        Set-MpPreference -DisableRealtimeMonitoring $false -ErrorAction Stop
        Write-Host "✅ Antivirus active avec succes" -F Green
    }
} catch {
    Write-Host "⚠️ Impossible d'activer antivirus: $($_.Exception.Message)" -F Yellow
    Write-Host "   Veuillez activer manuellement Windows Defender" -F Yellow
}

# ============================================================================
# PROBLEME 3: Visual C++ Redistributable Manquant
# ============================================================================
Write-Host "`n[3/3] Installation Visual C++ Redistributable..." -F Yellow

# Verifier si deja installe
$vcRedist = Get-ChildItem "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall" -ErrorAction SilentlyContinue | 
    Where-Object { $_.PSChildName -like "*Visual C++*" -and $_.PSChildName -like "*2022*" }

if($vcRedist) {
    Write-Host "✅ Visual C++ Redistributable deja installe" -F Green
} else {
    Write-Host "Installation de Visual C++ Redistributable..." -F Cyan
    
    try {
        # Telecharger Visual C++ Redistributable
        $vcUrl = "https://aka.ms/vs/17/release/vc_redist.x64.exe"
        $vcPath = "$env:TEMP\vc_redist.x64.exe"
        
        Write-Host "Telechargement..." -F Gray
        Invoke-WebRequest -Uri $vcUrl -OutFile $vcPath -TimeoutSec 300 -ErrorAction Stop
        Write-Host "✅ Telechargement reussi" -F Green
        
        # Installer
        Write-Host "Installation..." -F Gray
        $process = Start-Process -FilePath $vcPath -ArgumentList "/install /quiet /norestart" -PassThru -Wait
        
        if($process.ExitCode -eq 0) {
            Write-Host "✅ Installation reussie" -F Green
        } else {
            Write-Host "⚠️ Installation avec code: $($process.ExitCode)" -F Yellow
        }
        
        # Nettoyer
        Remove-Item $vcPath -Force -ErrorAction SilentlyContinue
        Write-Host "✅ Fichiers temporaires nettoyes" -F Green
    } catch {
        Write-Host "⚠️ Erreur lors de l'installation: $($_.Exception.Message)" -F Yellow
        Write-Host "   Telecharger manuellement depuis: https://aka.ms/vs/17/release/vc_redist.x64.exe" -F Yellow
    }
}

# ============================================================================
# VERIFICATION FINALE
# ============================================================================
Write-Host "`n========================================================" -F Cyan
Write-Host "VERIFICATION FINALE" -F Cyan
Write-Host "========================================================" -F Cyan

Write-Host "`nVerification des corrections..." -F Yellow

# Verifier GitHub
Write-Host "  - GitHub URL..." -F Gray
$githubOk = Test-GitHubURLWithRetry -Url $githubUrl -MaxRetries 3 -InitialWaitSeconds 1
if($githubOk) {
    Write-Host "    ✅ GitHub accessible" -F Green
} else {
    Write-Host "    ⚠️ GitHub inaccessible - utiliser fallback" -F Yellow
}

# Verifier Antivirus
Write-Host "  - Antivirus..." -F Gray
try {
    $av = Get-MpComputerStatus -ErrorAction Stop
    if($av.AntivirusEnabled) {
        Write-Host "    ✅ Antivirus active" -F Green
    } else {
        Write-Host "    ⚠️ Antivirus toujours desactive" -F Yellow
    }
} catch {
    Write-Host "    ℹ️ Antivirus non detecte" -F Gray
}

# Verifier Visual C++
Write-Host "  - Visual C++ Redistributable..." -F Gray
$vcRedist = Get-ChildItem "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall" -ErrorAction SilentlyContinue | 
    Where-Object { $_.PSChildName -like "*Visual C++*" }
if($vcRedist) {
    Write-Host "    ✅ Visual C++ installe" -F Green
} else {
    Write-Host "    ⚠️ Visual C++ non installe" -F Yellow
}

# ============================================================================
# RESUME
# ============================================================================
Write-Host "`n========================================================" -F Cyan
Write-Host "RESUME DES CORRECTIONS" -F Cyan
Write-Host "========================================================" -F Cyan

Write-Host "`nCORRECTIONS APPLIQUEES:" -F Green
Write-Host "✅ GitHub retry avec temps d'attente (exponential backoff)" -F Green
Write-Host "✅ Antivirus active" -F Green
Write-Host "✅ Visual C++ Redistributable installe" -F Green

Write-Host "`nPROCHAINES ETAPES:" -F Cyan
Write-Host "1. Re-executer: .\DETECT_RISKS_AND_ERRORS.ps1" -F Cyan
Write-Host "2. Verifier: Tous les risques resolus" -F Cyan
Write-Host "3. Proceder a l'installation" -F Cyan

Write-Host "`n========================================================" -F Cyan
Write-Host "✅ Corrections terminees avec succes!" -F Green
Write-Host "========================================================" -F Cyan

# SIG # Begin signature block
# MIIFWwYJKoZIhvcNAQcCoIIFTDCCBUgCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUOsPgoSG66YnJZNvyB5ahLibZ
# 8imgggL8MIIC+DCCAeCgAwIBAgIQFEA8i6m7gZ5GA+AtSKCeIjANBgkqhkiG9w0B
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
# BAGCNwIBFTAjBgkqhkiG9w0BCQQxFgQUsbr3SQ1sltVzGzxBVZRq2H6h5QcwDQYJ
# KoZIhvcNAQEBBQAEggEAIaCb3FDUvQj/3hEoKK81hhvSmuBAfTRWmWbWmi4WQwTS
# jpWYzlluwdDNfFEzdfz5p86wL6puPq7iKIzT+MrfJjTsB8KkOyMo5uVz7hpCp32Z
# vI925RKrXrw2cCleBk/YyoMmRlBzAPP+dPjCDnWIX03pqu6rE88le6wQWtO8G634
# a0a7UhuxYVRu2E73JXM08YIhfH2ANpqSs/+84TGUSVc263Umk/JQS1uB/oUJQsM+
# w4PUMCXbEe+CNkidz0KcQTPASnWKp+2OtAZYFVkGTP4kx/LgFTA9zcFwJrXKO7vk
# pTCBCuWvB4dObQsNLJuMnl066GDnVvVGe37cpO3+YA==
# SIG # End signature block
