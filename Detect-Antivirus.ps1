# ===============================================
# DETECT-ANTIVIRUS.PS1 - Detection Antivirus Tiers
# ===============================================
# Date: 27 Novembre 2025
# Version: 1.0
# Description: Detection et adaptation selon antivirus installes
# ===============================================

$ErrorActionPreference = "Stop"

# ===============================================
# FONCTION: Detecter Antivirus Windows Defender
# ===============================================
function Get-WindowsDefender {
    Write-Host "`nDetection Windows Defender..." -F Cyan
    
    try {
        $defender = Get-MpComputerStatus -ErrorAction Stop
        
        $info = @{
            Name = "Windows Defender"
            Enabled = $defender.AntivirusEnabled
            RealTimeProtection = $defender.RealTimeProtectionEnabled
            BehaviorMonitor = $defender.BehaviorMonitorEnabled
            CloudProtection = $defender.MAPSReporting -gt 0
            Version = $defender.AntivirusSignatureVersion
            LastUpdate = $defender.AntivirusSignatureLastUpdated
        }
        
        Write-Host "  Nom: Windows Defender" -F Green
        Write-Host "  Active: $($info.Enabled)" -F $(if($info.Enabled) { "Green" } else { "Red" })
        Write-Host "  Protection temps reel: $($info.RealTimeProtection)" -F Gray
        Write-Host "  Version: $($info.Version)" -F Gray
        
        return $info
        
    } catch {
        Write-Host "  Windows Defender non disponible" -F Yellow
        return $null
    }
}

# ===============================================
# FONCTION: Detecter Antivirus Tiers
# ===============================================
function Get-ThirdPartyAntivirus {
    Write-Host "`nDetection antivirus tiers..." -F Cyan
    
    try {
        $av = Get-WmiObject -Namespace "root\SecurityCenter2" `
            -Class AntiVirusProduct -ErrorAction Stop
        
        if(-not $av) {
            Write-Host "  Aucun antivirus tiers detecte" -F Gray
            return @()
        }
        
        $avList = @()
        
        foreach($product in $av) {
            # Decoder le state
            $hexState = [Convert]::ToString($product.productState, 16).PadLeft(6, '0')
            $enabled = $hexState.Substring(2, 2) -eq "10"
            $upToDate = $hexState.Substring(4, 2) -eq "00"
            
            $info = @{
                Name = $product.displayName
                Publisher = $product.pathToSignedProductExe
                Enabled = $enabled
                UpToDate = $upToDate
                ProductState = $product.productState
                Timestamp = $product.timestamp
            }
            
            Write-Host "  Nom: $($info.Name)" -F Green
            Write-Host "  Active: $($info.Enabled)" -F $(if($info.Enabled) { "Green" } else { "Red" })
            Write-Host "  A jour: $($info.UpToDate)" -F Gray
            
            $avList += $info
        }
        
        return $avList
        
    } catch {
        Write-Host "  Impossible de detecter antivirus tiers" -F Yellow
        return @()
    }
}

# ===============================================
# FONCTION: Detecter Pare-feu
# ===============================================
function Get-FirewallStatus {
    Write-Host "`nDetection pare-feu..." -F Cyan
    
    try {
        $profiles = Get-NetFirewallProfile -ErrorAction Stop
        
        $firewallInfo = @()
        
        foreach($profile in $profiles) {
            $info = @{
                Profile = $profile.Name
                Enabled = $profile.Enabled
                DefaultInbound = $profile.DefaultInboundAction
                DefaultOutbound = $profile.DefaultOutboundAction
            }
            
            Write-Host "  Profil: $($info.Profile)" -F Green
            Write-Host "  Active: $($info.Enabled)" -F $(if($info.Enabled) { "Green" } else { "Red" })
            
            $firewallInfo += $info
        }
        
        return $firewallInfo
        
    } catch {
        Write-Host "  Impossible de detecter pare-feu" -F Yellow
        return @()
    }
}

# ===============================================
# FONCTION: Detecter EDR/XDR
# ===============================================
function Get-EDRStatus {
    Write-Host "`nDetection EDR/XDR..." -F Cyan
    
    $edrList = @(
        "SentinelOne",
        "CrowdStrike",
        "Carbon Black",
        "Cylance",
        "Palo Alto",
        "Microsoft Defender ATP",
        "Trend Micro",
        "Symantec Endpoint",
        "McAfee Endpoint"
    )
    
    $detected = @()
    
    foreach($edr in $edrList) {
        # Verifier processus
        $process = Get-Process | Where-Object { $_.ProcessName -like "*$edr*" }
        
        if($process) {
            Write-Host "  Detecte: $edr" -F Yellow
            $detected += @{
                Name = $edr
                ProcessName = $process.ProcessName
                ProcessCount = $process.Count
            }
        }
    }
    
    if($detected.Count -eq 0) {
        Write-Host "  Aucun EDR/XDR detecte" -F Gray
    }
    
    return $detected
}

# ===============================================
# FONCTION: Recommandations selon Antivirus
# ===============================================
function Get-Recommendations {
    param(
        [object]$Defender,
        [array]$ThirdParty,
        [array]$Firewall,
        [array]$EDR
    )
    
    Write-Host "`n=========================================" -F Cyan
    Write-Host "RECOMMANDATIONS" -F Cyan
    Write-Host "=========================================`n" -F Cyan
    
    $recommendations = @()
    
    # Windows Defender
    if($Defender) {
        if($Defender.Enabled) {
            $recommendations += "Utiliser whitelist Windows Defender (Add-MpPreference)"
            Write-Host "  Windows Defender active: Utiliser whitelist" -F Green
        } else {
            $recommendations += "Activer Windows Defender avant installation"
            Write-Host "  Windows Defender desactive: Activer avant installation" -F Yellow
        }
    }
    
    # Antivirus tiers
    if($ThirdParty.Count -gt 0) {
        foreach($av in $ThirdParty) {
            $recommendations += "Configurer whitelist pour: $($av.Name)"
            Write-Host "  Antivirus tiers detecte: $($av.Name)" -F Yellow
            Write-Host "    Action: Configurer whitelist manuellement" -F Gray
        }
    }
    
    # EDR/XDR
    if($EDR.Count -gt 0) {
        foreach($edr in $EDR) {
            $recommendations += "ATTENTION: EDR detecte ($($edr.Name)) - Contacter equipe securite"
            Write-Host "  EDR/XDR detecte: $($edr.Name)" -F Red
            Write-Host "    Action: CONTACTER EQUIPE SECURITE" -F Red
        }
    }
    
    # Pare-feu
    $firewallEnabled = $Firewall | Where-Object { $_.Enabled -eq $true }
    if($firewallEnabled) {
        $recommendations += "Pare-feu actif: Verifier regles sortantes"
        Write-Host "  Pare-feu actif: Verifier regles sortantes" -F Cyan
    }
    
    return $recommendations
}

# ===============================================
# FONCTION: Generer Rapport
# ===============================================
function Export-Report {
    param(
        [object]$Defender,
        [array]$ThirdParty,
        [array]$Firewall,
        [array]$EDR,
        [array]$Recommendations
    )
    
    $report = @{
        Timestamp = Get-Date
        Computer = $env:COMPUTERNAME
        User = $env:USERNAME
        WindowsDefender = $Defender
        ThirdPartyAntivirus = $ThirdParty
        Firewall = $Firewall
        EDR = $EDR
        Recommendations = $Recommendations
    }
    
    $reportPath = Join-Path $PSScriptRoot "antivirus-detection-report.json"
    $report | ConvertTo-Json -Depth 10 | Out-File -FilePath $reportPath -Encoding UTF8
    
    Write-Host "`nRapport exporte: $reportPath" -F Green
    
    return $reportPath
}

# ===============================================
# EXECUTION PRINCIPALE
# ===============================================

Write-Host "`n=========================================" -F Cyan
Write-Host "CLOUDFARE - DETECTION ANTIVIRUS" -F Cyan
Write-Host "=========================================`n" -F Cyan
Write-Host "Ordinateur: $env:COMPUTERNAME" -F Gray
Write-Host "Utilisateur: $env:USERNAME" -F Gray
Write-Host "Date: $(Get-Date)" -F Gray

# Detecter tous les antivirus
$defender = Get-WindowsDefender
$thirdParty = Get-ThirdPartyAntivirus
$firewall = Get-FirewallStatus
$edr = Get-EDRStatus

# Generer recommandations
$recommendations = Get-Recommendations -Defender $defender -ThirdParty $thirdParty -Firewall $firewall -EDR $edr

# Exporter rapport
$reportPath = Export-Report -Defender $defender -ThirdParty $thirdParty -Firewall $firewall -EDR $edr -Recommendations $recommendations

Write-Host "`n=========================================" -F Green
Write-Host "DETECTION COMPLETE!" -F Green
Write-Host "=========================================`n" -F Green

# Afficher resume
Write-Host "RESUME:" -F Cyan
Write-Host "  Windows Defender: $(if($defender) { 'Detecte' } else { 'Non detecte' })" -F Gray
Write-Host "  Antivirus tiers: $($thirdParty.Count)" -F Gray
Write-Host "  EDR/XDR: $($edr.Count)" -F Gray
Write-Host "  Recommandations: $($recommendations.Count)" -F Gray
Write-Host "`nRapport: $reportPath" -F Green

# SIG # Begin signature block
# MIIFWwYJKoZIhvcNAQcCoIIFTDCCBUgCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUxaqMtZtHwqs15xhbCY1rcvfX
# SRigggL8MIIC+DCCAeCgAwIBAgIQFEA8i6m7gZ5GA+AtSKCeIjANBgkqhkiG9w0B
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
# BAGCNwIBFTAjBgkqhkiG9w0BCQQxFgQUyrF/muTVll8lKJ3naiZg+aZw3jQwDQYJ
# KoZIhvcNAQEBBQAEggEAii4GDz9SCGHYYuFF7oPoayzchobXmD9dt9JCdKMwWkt+
# VmcncIBpRSnvSjy9RKF1ams4Z+rnxxW5bRlC2olYQO3wcsITKdvQQ/LX4wq0MjnG
# wx2agpg6e/mqh7OKyN9fbJEQUreR3GQtdwPYyx4GzlLgQdxibbUG+h8iP6Kuh25K
# iqrYggDpNGKUqaD0129iEuIpzl/Wh4n4hHzsP95JVNVH9ntpwh4cD/2nWoiMGB+p
# Xl94/jgnFDQhL7PKZ5FnWKyoNpMiEZJ8n0biZaOALTtC5/iRYGt7mfoSaqMkAabO
# Fu9Fp0vtivKUZmbR1WS7DbFOtEss5S6uWIZCIjgUUw==
# SIG # End signature block
