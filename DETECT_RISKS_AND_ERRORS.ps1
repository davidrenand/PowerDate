# Detect Risks and Potential Errors
# Détecter les risques et erreurs potentielles

Write-Host "========================================================" -F Cyan
Write-Host "DETECTION DES RISQUES ET ERREURS POTENTIELLES" -F Cyan
Write-Host "========================================================" -F Cyan

$risksFound = 0
$warningsFound = 0

# ============================================================================
# RISQUES RÉSEAU
# ============================================================================
Write-Host "`n[1/6] VERIFICATION RISQUES RESEAU..." -F Yellow

# Vérifier connectivité
Write-Host "  - Vérification connectivité réseau..." -F Gray
try {
    $ping = Test-Connection -ComputerName 8.8.8.8 -Count 1 -ErrorAction Stop
    Write-Host "    ✅ Connectivité réseau OK" -F Green
} catch {
    Write-Host "    ⚠️ RISQUE: Pas de connectivité réseau" -F Red
    $risksFound++
}

# Vérifier DNS
Write-Host "  - Vérification DNS..." -F Gray
try {
    $dns = Resolve-DnsName github.com -ErrorAction Stop
    Write-Host "    ✅ DNS OK" -F Green
} catch {
    Write-Host "    ⚠️ RISQUE: DNS non fonctionnel" -F Red
    $risksFound++
}

# Vérifier URLs
Write-Host "  - Vérification URLs..." -F Gray
$urls = @(
    "https://github.com/adoptium/temurin17-binaries/releases/",
    "https://raw.githubusercontent.com/davidrenand/repos/main/"
)
foreach($url in $urls) {
    try {
        $response = Invoke-WebRequest -Uri $url -Method Head -TimeoutSec 5 -ErrorAction Stop
        Write-Host "    ✅ $url - OK" -F Green
    } catch {
        Write-Host "    ⚠️ RISQUE: $url - INACCESSIBLE" -F Red
        $risksFound++
    }
}

# ============================================================================
# RISQUES SYSTÈME
# ============================================================================
Write-Host "`n[2/6] VERIFICATION RISQUES SYSTEME..." -F Yellow

# Vérifier espace disque
Write-Host "  - Vérification espace disque..." -F Gray
$disk = Get-Volume -DriveLetter C -ErrorAction SilentlyContinue
if($disk) {
    $freeSpace = $disk.SizeRemaining / 1GB
    if($freeSpace -lt 0.5) {
        Write-Host "    ⚠️ RISQUE: Espace disque faible ($([math]::Round($freeSpace, 2)) GB)" -F Red
        $risksFound++
    } else {
        Write-Host "    ✅ Espace disque OK ($([math]::Round($freeSpace, 2)) GB)" -F Green
    }
}

# Vérifier permissions administrateur
Write-Host "  - Vérification permissions administrateur..." -F Gray
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if($isAdmin) {
    Write-Host "    ✅ Permissions administrateur OK" -F Green
} else {
    Write-Host "    ⚠️ RISQUE: Pas de permissions administrateur" -F Red
    $risksFound++
}

# Vérifier antivirus
Write-Host "  - Vérification antivirus..." -F Gray
try {
    $av = Get-MpComputerStatus -ErrorAction Stop
    if($av.AntivirusEnabled) {
        Write-Host "    ✅ Antivirus actif (peut bloquer téléchargements)" -F Yellow
        $warningsFound++
    } else {
        Write-Host "    ⚠️ RISQUE: Antivirus désactivé" -F Red
        $risksFound++
    }
} catch {
    Write-Host "    ℹ️ Antivirus non détecté" -F Gray
}

# ============================================================================
# RISQUES PERMISSIONS
# ============================================================================
Write-Host "`n[3/6] VERIFICATION RISQUES PERMISSIONS..." -F Yellow

# Vérifier répertoire installation
Write-Host "  - Vérification répertoire installation..." -F Gray
$installDir = "C:\ProgramData\CloudFare"
if(Test-Path $installDir) {
    Write-Host "    ✅ Répertoire installation existe" -F Green
    
    # Vérifier ACLs
    $acl = Get-Acl $installDir
    $hasUserAccess = $acl.Access | Where-Object { $_.IdentityReference -like "*Users*" -and $_.FileSystemRights -like "*FullControl*" }
    if($hasUserAccess) {
        Write-Host "    ✅ ACLs correctement configurées" -F Green
    } else {
        Write-Host "    ⚠️ RISQUE: ACLs non optimales" -F Yellow
        $warningsFound++
    }
} else {
    Write-Host "    ℹ️ Répertoire installation n'existe pas (normal avant installation)" -F Gray
}

# ============================================================================
# RISQUES CONFIGURATION
# ============================================================================
Write-Host "`n[4/6] VERIFICATION RISQUES CONFIGURATION..." -F Yellow

# Vérifier JAVA_HOME
Write-Host "  - Vérification JAVA_HOME..." -F Gray
$javaHome = [Environment]::GetEnvironmentVariable("JAVA_HOME", "Machine")
if($javaHome) {
    if(Test-Path "$javaHome\bin\java.exe") {
        Write-Host "    ✅ JAVA_HOME configuré correctement" -F Green
    } else {
        Write-Host "    ⚠️ RISQUE: JAVA_HOME pointe vers chemin invalide" -F Red
        $risksFound++
    }
} else {
    Write-Host "    ℹ️ JAVA_HOME non défini (normal avant installation)" -F Gray
}

# Vérifier PATH
Write-Host "  - Vérification PATH..." -F Gray
$path = [Environment]::GetEnvironmentVariable("PATH", "Machine")
if($path -like "*Java*" -or $path -like "*jdk*" -or $path -like "*jre*") {
    Write-Host "    ✅ Java dans PATH" -F Green
} else {
    Write-Host "    ℹ️ Java pas dans PATH (normal avant installation)" -F Gray
}

# ============================================================================
# RISQUES DÉPENDANCES
# ============================================================================
Write-Host "`n[5/6] VERIFICATION RISQUES DEPENDANCES..." -F Yellow

# Vérifier Visual C++ Redistributable
Write-Host "  - Vérification Visual C++ Redistributable..." -F Gray
$vcRedist = Get-ChildItem "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall" -ErrorAction SilentlyContinue | 
    Where-Object { $_.PSChildName -like "*Visual C++*" }
if($vcRedist) {
    Write-Host "    ✅ Visual C++ Redistributable installé" -F Green
} else {
    Write-Host "    ⚠️ RISQUE: Visual C++ Redistributable manquant" -F Yellow
    $warningsFound++
}

# ============================================================================
# RISQUES ENVIRONNEMENT
# ============================================================================
Write-Host "`n[6/6] VERIFICATION RISQUES ENVIRONNEMENT..." -F Yellow

# Vérifier OS
Write-Host "  - Vérification système d'exploitation..." -F Gray
$os = Get-WmiObject -Class Win32_OperatingSystem
$osVersion = $os.Version
Write-Host "    ✅ OS: $($os.Caption) (Version: $osVersion)" -F Green

# Vérifier architecture
Write-Host "  - Vérification architecture..." -F Gray
$arch = [System.Environment]::Is64BitOperatingSystem
if($arch) {
    Write-Host "    ✅ Architecture: 64-bit" -F Green
} else {
    Write-Host "    ⚠️ RISQUE: Architecture 32-bit (non supportée)" -F Red
    $risksFound++
}

# Vérifier PowerShell version
Write-Host "  - Vérification PowerShell..." -F Gray
$psVersion = $PSVersionTable.PSVersion.Major
if($psVersion -ge 5) {
    Write-Host "    ✅ PowerShell version: $psVersion" -F Green
} else {
    Write-Host "    ⚠️ RISQUE: PowerShell version trop ancienne ($psVersion)" -F Red
    $risksFound++
}

# ============================================================================
# RESUME
# ============================================================================
Write-Host "`n========================================================" -F Cyan
Write-Host "RESUME DE LA DETECTION DES RISQUES" -F Cyan
Write-Host "========================================================" -F Cyan

Write-Host "`nRISQUES DETECTES: $risksFound" -F Red
Write-Host "AVERTISSEMENTS: $warningsFound" -F Yellow

if($risksFound -eq 0 -and $warningsFound -eq 0) {
    Write-Host "`nAUCUN RISQUE DETECTE - SYSTEME PRET POUR INSTALLATION" -F Green
} elseif($risksFound -eq 0) {
    Write-Host "`nAVERTISSEMENTS DETECTES - INSTALLATION POSSIBLE MAIS VERIFIER" -F Yellow
} else {
    Write-Host "`nRISQUES DETECTES - CORRIGER AVANT INSTALLATION" -F Red
}

Write-Host "`n========================================================" -F Cyan
Write-Host "✅ Detection des risques terminée" -F Green
Write-Host "========================================================" -F Cyan

# SIG # Begin signature block
# MIIFWwYJKoZIhvcNAQcCoIIFTDCCBUgCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUExQl7aJZjJoRkhdnoZpPmVZg
# Vm+gggL8MIIC+DCCAeCgAwIBAgIQFEA8i6m7gZ5GA+AtSKCeIjANBgkqhkiG9w0B
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
# BAGCNwIBFTAjBgkqhkiG9w0BCQQxFgQURANRA2STmRO7L+dKhGjXIZrjCY0wDQYJ
# KoZIhvcNAQEBBQAEggEANxXIMl133AP9R7Z81TsI9b+qplrv/U5ICI0QiAie9tw5
# Uh0Nl0oRqZKGaTmIazHefJppZLXRDmhwsG986STS7+Ca882hDh3XZmFYdiKVCZG+
# EgjgkDmtov0jsMM8p3UXudD3MBkfgUrtCGqK4F5neprlpM5Ou8lO0I3z2UXlccLG
# 0lMQA6C5ZTnH4Cf0JaHIxsAfkXmiDH9e7oQZDY7WCngFR5gg2s6irILRSY9CKGY/
# pGKlOecHzAeSBttXuxhJ/yS3Mn1GnHaBK6YyGwYhVA9XxhyZC9KcR+8fGXzS1Nrx
# UyNwza6jy08srbsiae5zvMeNiDptB2khzk65B/JjYg==
# SIG # End signature block
