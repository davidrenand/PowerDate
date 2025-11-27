# ===============================================
# NOTIFY-IT.PS1 - Notification Equipe IT
# ===============================================
# Date: 27 Novembre 2025
# Version: 1.0
# Description: Notifications et logs d'audit pour equipe IT
# ===============================================

param(
    [string]$Action = "Installation",
    [string]$Details = "",
    [string]$Email = "it-security@company.com",
    [switch]$SendEmail,
    [switch]$CreateTicket
)

$ErrorActionPreference = "Stop"

# ===============================================
# FONCTION: Creer Notification
# ===============================================
function New-ITNotification {
    param(
        [string]$Action,
        [string]$Details
    )
    
    $notification = @{
        Timestamp = Get-Date
        Computer = $env:COMPUTERNAME
        User = $env:USERNAME
        Domain = $env:USERDOMAIN
        Action = $Action
        Details = $Details
        OSVersion = (Get-WmiObject Win32_OperatingSystem).Caption
        Architecture = $env:PROCESSOR_ARCHITECTURE
        ScriptPath = $PSScriptRoot
        PowerShellVersion = $PSVersionTable.PSVersion.ToString()
    }
    
    return $notification
}

# ===============================================
# FONCTION: Afficher Notification Console
# ===============================================
function Show-Notification {
    param([hashtable]$Notification)
    
    Write-Host "`n=========================================" -F Yellow
    Write-Host "NOTIFICATION IT REQUISE" -F Yellow
    Write-Host "=========================================`n" -F Yellow
    
    Write-Host "Date/Heure: $($Notification.Timestamp)" -F Cyan
    Write-Host "Ordinateur: $($Notification.Computer)" -F Cyan
    Write-Host "Utilisateur: $($Notification.User)" -F Cyan
    Write-Host "Domaine: $($Notification.Domain)" -F Cyan
    Write-Host "`nAction: $($Notification.Action)" -F White
    Write-Host "Details: $($Notification.Details)" -F White
    Write-Host "`nSysteme:" -F Gray
    Write-Host "  OS: $($Notification.OSVersion)" -F Gray
    Write-Host "  Architecture: $($Notification.Architecture)" -F Gray
    Write-Host "  PowerShell: v$($Notification.PowerShellVersion)" -F Gray
    Write-Host "  Chemin: $($Notification.ScriptPath)" -F Gray
    
    Write-Host "`n=========================================" -F Yellow
    Write-Host "CONTACTER: $Email" -F Yellow
    Write-Host "=========================================`n" -F Yellow
}

# ===============================================
# FONCTION: Enregistrer dans Log
# ===============================================
function Save-NotificationLog {
    param([hashtable]$Notification)
    
    $logDir = Join-Path $env:ProgramData "CloudFare\Logs"
    if(-not (Test-Path $logDir)) {
        New-Item -Path $logDir -ItemType Directory -Force | Out-Null
    }
    
    $logFile = Join-Path $logDir "it-notifications.log"
    
    $logEntry = @"
[$($Notification.Timestamp)] $($Notification.Computer)\$($Notification.User)
Action: $($Notification.Action)
Details: $($Notification.Details)
OS: $($Notification.OSVersion) ($($Notification.Architecture))
PowerShell: v$($Notification.PowerShellVersion)
Path: $($Notification.ScriptPath)
---
"@
    
    Add-Content -Path $logFile -Value $logEntry -Encoding UTF8
    
    Write-Host "Log enregistre: $logFile" -F Green
    
    return $logFile
}

# ===============================================
# FONCTION: Enregistrer en JSON
# ===============================================
function Save-NotificationJSON {
    param([hashtable]$Notification)
    
    $jsonDir = Join-Path $env:ProgramData "CloudFare\Logs"
    if(-not (Test-Path $jsonDir)) {
        New-Item -Path $jsonDir -ItemType Directory -Force | Out-Null
    }
    
    $timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
    $jsonFile = Join-Path $jsonDir "notification-$timestamp.json"
    
    $Notification | ConvertTo-Json -Depth 10 | Out-File -FilePath $jsonFile -Encoding UTF8
    
    Write-Host "JSON enregistre: $jsonFile" -F Green
    
    return $jsonFile
}

# ===============================================
# FONCTION: Generer Email
# ===============================================
function New-EmailNotification {
    param(
        [hashtable]$Notification,
        [string]$ToEmail
    )
    
    $subject = "CloudFare Installation - $($Notification.Action) - $($Notification.Computer)"
    
    $body = @"
<html>
<head>
    <style>
        body { font-family: Arial, sans-serif; }
        h1 { color: #0066cc; }
        table { border-collapse: collapse; width: 100%; }
        th, td { border: 1px solid #ddd; padding: 8px; text-align: left; }
        th { background-color: #0066cc; color: white; }
        .important { color: #cc0000; font-weight: bold; }
    </style>
</head>
<body>
    <h1>Notification CloudFare Installation</h1>
    
    <h2>Details de l'Action</h2>
    <table>
        <tr><th>Propriete</th><th>Valeur</th></tr>
        <tr><td>Action</td><td class="important">$($Notification.Action)</td></tr>
        <tr><td>Details</td><td>$($Notification.Details)</td></tr>
        <tr><td>Date/Heure</td><td>$($Notification.Timestamp)</td></tr>
    </table>
    
    <h2>Informations Systeme</h2>
    <table>
        <tr><th>Propriete</th><th>Valeur</th></tr>
        <tr><td>Ordinateur</td><td>$($Notification.Computer)</td></tr>
        <tr><td>Utilisateur</td><td>$($Notification.User)</td></tr>
        <tr><td>Domaine</td><td>$($Notification.Domain)</td></tr>
        <tr><td>OS</td><td>$($Notification.OSVersion)</td></tr>
        <tr><td>Architecture</td><td>$($Notification.Architecture)</td></tr>
        <tr><td>PowerShell</td><td>v$($Notification.PowerShellVersion)</td></tr>
        <tr><td>Chemin</td><td>$($Notification.ScriptPath)</td></tr>
    </table>
    
    <p><strong>Cette notification est generee automatiquement par le systeme CloudFare.</strong></p>
</body>
</html>
"@
    
    $emailData = @{
        To = $ToEmail
        Subject = $subject
        Body = $body
        IsBodyHtml = $true
    }
    
    # Sauvegarder l'email dans un fichier pour envoi manuel
    $emailDir = Join-Path $env:ProgramData "CloudFare\Logs"
    if(-not (Test-Path $emailDir)) {
        New-Item -Path $emailDir -ItemType Directory -Force | Out-Null
    }
    
    $timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
    $emailFile = Join-Path $emailDir "email-$timestamp.html"
    
    $body | Out-File -FilePath $emailFile -Encoding UTF8
    
    Write-Host "Email genere: $emailFile" -F Green
    Write-Host "  Destinataire: $ToEmail" -F Gray
    Write-Host "  Sujet: $subject" -F Gray
    
    return $emailFile
}

# ===============================================
# FONCTION: Creer Ticket
# ===============================================
function New-ITTicket {
    param([hashtable]$Notification)
    
    $ticket = @{
        TicketID = "CF-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
        Created = $Notification.Timestamp
        Status = "New"
        Priority = "Medium"
        Category = "Software Installation"
        Subcategory = "CloudFare"
        RequestedBy = "$($Notification.Domain)\$($Notification.User)"
        Computer = $Notification.Computer
        Description = "$($Notification.Action): $($Notification.Details)"
        SystemInfo = @{
            OS = $Notification.OSVersion
            Architecture = $Notification.Architecture
            PowerShell = $Notification.PowerShellVersion
            Path = $Notification.ScriptPath
        }
    }
    
    $ticketDir = Join-Path $env:ProgramData "CloudFare\Logs"
    if(-not (Test-Path $ticketDir)) {
        New-Item -Path $ticketDir -ItemType Directory -Force | Out-Null
    }
    
    $ticketFile = Join-Path $ticketDir "$($ticket.TicketID).json"
    $ticket | ConvertTo-Json -Depth 10 | Out-File -FilePath $ticketFile -Encoding UTF8
    
    Write-Host "`nTicket cree: $($ticket.TicketID)" -F Green
    Write-Host "  Fichier: $ticketFile" -F Gray
    Write-Host "  Statut: $($ticket.Status)" -F Gray
    Write-Host "  Priorite: $($ticket.Priority)" -F Gray
    
    return $ticket
}

# ===============================================
# FONCTION: Generer Audit Trail
# ===============================================
function New-AuditTrail {
    param([hashtable]$Notification)
    
    $auditDir = Join-Path $env:ProgramData "CloudFare\Audit"
    if(-not (Test-Path $auditDir)) {
        New-Item -Path $auditDir -ItemType Directory -Force | Out-Null
    }
    
    $auditFile = Join-Path $auditDir "audit-trail.log"
    
    $auditEntry = @"
[AUDIT] $($Notification.Timestamp)
Computer: $($Notification.Computer)
User: $($Notification.Domain)\$($Notification.User)
Action: $($Notification.Action)
Details: $($Notification.Details)
OS: $($Notification.OSVersion) ($($Notification.Architecture))
PowerShell: v$($Notification.PowerShellVersion)
Path: $($Notification.ScriptPath)
Hash: $(Get-FileHash -Path $PSCommandPath -Algorithm SHA256 | Select-Object -ExpandProperty Hash)
---
"@
    
    Add-Content -Path $auditFile -Value $auditEntry -Encoding UTF8
    
    Write-Host "Audit trail enregistre: $auditFile" -F Green
    
    return $auditFile
}

# ===============================================
# EXECUTION PRINCIPALE
# ===============================================

Write-Host "`n=========================================" -F Cyan
Write-Host "CLOUDFARE - NOTIFICATION IT" -F Cyan
Write-Host "=========================================`n" -F Cyan

# Creer notification
$notification = New-ITNotification -Action $Action -Details $Details

# Afficher notification
Show-Notification -Notification $notification

# Enregistrer logs
$logFile = Save-NotificationLog -Notification $notification
$jsonFile = Save-NotificationJSON -Notification $notification
$auditFile = New-AuditTrail -Notification $notification

# Generer email si demande
if($SendEmail) {
    $emailFile = New-EmailNotification -Notification $notification -ToEmail $Email
}

# Creer ticket si demande
if($CreateTicket) {
    $ticket = New-ITTicket -Notification $notification
}

Write-Host "`n=========================================" -F Green
Write-Host "NOTIFICATION COMPLETE!" -F Green
Write-Host "=========================================`n" -F Green

Write-Host "Fichiers generes:" -F Cyan
Write-Host "  Log: $logFile" -F Gray
Write-Host "  JSON: $jsonFile" -F Gray
Write-Host "  Audit: $auditFile" -F Gray
if($SendEmail) { Write-Host "  Email: $emailFile" -F Gray }
if($CreateTicket) { Write-Host "  Ticket: $($ticket.TicketID)" -F Gray }

Write-Host "`nNotification IT terminee!" -F Green

# SIG # Begin signature block
# MIIFWwYJKoZIhvcNAQcCoIIFTDCCBUgCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQU8MrBxteCpoHG4pVEhl78THE0
# 1qigggL8MIIC+DCCAeCgAwIBAgIQFEA8i6m7gZ5GA+AtSKCeIjANBgkqhkiG9w0B
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
# BAGCNwIBFTAjBgkqhkiG9w0BCQQxFgQUSGX4gJk9u3Nou9y0N54/jAYbyHwwDQYJ
# KoZIhvcNAQEBBQAEggEAXzoOcFO/Bmtk+nfn73FCsbIgozJMkXKa72SEPgJlraxV
# h7s2l3oWf79WvA7KWmEQR4e2ZvFpaEnabT7ruT2mStVizJMNZxxeAD8d3sVYSZTX
# QDs0qoA6blP0S3BG4g3UG12vFkvVKc2Ny+kma+GMvliUO8DSvXQZTBDSmHr3dEau
# /1i3vKoBj0q22lnLiwAhpz2VVmBxKRMdnW2QWd8DXqPjNut85NCLlqlmHgeTpmSZ
# P8BXk9gNvyzvHdkhLOfSJ/cGQSZI0Hx4HmE2n2h8V+VD48/vzPuZ+YsLZv3YZxEx
# P0cfCq3inAnCG8k/7i9ybCXbMRoX5JGH+JKlsEwbUQ==
# SIG # End signature block
