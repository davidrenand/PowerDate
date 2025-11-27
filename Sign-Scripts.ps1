# ===============================================
# SIGN-SCRIPTS.PS1 - Signature Numerique
# ===============================================
# Date: 27 Novembre 2025
# Version: 1.0
# Description: Signature numerique automatique des scripts PowerShell
# ===============================================

param(
    [string]$ScriptPath = $PSScriptRoot,
    [switch]$CreateCertificate,
    [switch]$SignAll
)

$ErrorActionPreference = "Stop"

# ===============================================
# FONCTION: Creer Certificat Auto-Signe
# ===============================================
function New-CloudFareCertificate {
    Write-Host "`n=========================================" -F Cyan
    Write-Host "CREATION CERTIFICAT AUTO-SIGNE" -F Cyan
    Write-Host "=========================================`n" -F Cyan
    
    try {
        # Verifier si certificat existe deja
        $existingCert = Get-ChildItem Cert:\CurrentUser\My | 
            Where-Object { $_.Subject -like "*CN=CloudFare*" } |
            Select-Object -First 1
        
        if($existingCert) {
            Write-Host "Certificat existant trouve:" -F Yellow
            Write-Host "  Subject: $($existingCert.Subject)" -F Gray
            Write-Host "  Thumbprint: $($existingCert.Thumbprint)" -F Gray
            Write-Host "  Expiration: $($existingCert.NotAfter)" -F Gray
            
            $replace = Read-Host "`nRemplacer? (O/N)"
            if($replace -ne "O") {
                Write-Host "Utilisation du certificat existant" -F Green
                return $existingCert
            }
            
            # Supprimer ancien certificat
            Remove-Item -Path "Cert:\CurrentUser\My\$($existingCert.Thumbprint)" -Force
            Write-Host "Ancien certificat supprime" -F Yellow
        }
        
        # Creer nouveau certificat
        Write-Host "Creation nouveau certificat..." -F Cyan
        
        $cert = New-SelfSignedCertificate `
            -CertStoreLocation Cert:\CurrentUser\My `
            -Subject "CN=CloudFare" `
            -KeyUsage DigitalSignature `
            -Type CodeSigningCert `
            -NotAfter (Get-Date).AddYears(5) `
            -ErrorAction Stop
        
        Write-Host "`nCertificat cree avec succes!" -F Green
        Write-Host "  Subject: $($cert.Subject)" -F Gray
        Write-Host "  Thumbprint: $($cert.Thumbprint)" -F Gray
        Write-Host "  Expiration: $($cert.NotAfter)" -F Gray
        
        # Exporter certificat pour partage
        $exportPath = Join-Path $ScriptPath "CloudFare-Certificate.cer"
        Export-Certificate -Cert $cert -FilePath $exportPath -Force | Out-Null
        Write-Host "  Exporte vers: $exportPath" -F Gray
        
        return $cert
        
    } catch {
        Write-Host "ERREUR creation certificat: $($_.Exception.Message)" -F Red
        return $null
    }
}

# ===============================================
# FONCTION: Signer un Script
# ===============================================
function Sign-PowerShellScript {
    param(
        [string]$FilePath,
        [System.Security.Cryptography.X509Certificates.X509Certificate2]$Certificate
    )
    
    try {
        # Verifier si fichier existe
        if(-not (Test-Path $FilePath)) {
            Write-Host "  ERREUR: Fichier non trouve: $FilePath" -F Red
            return $false
        }
        
        # Verifier si deja signe
        $signature = Get-AuthenticodeSignature -FilePath $FilePath
        if($signature.Status -eq "Valid") {
            Write-Host "  Deja signe: $(Split-Path $FilePath -Leaf)" -F Gray
            return $true
        }
        
        # Signer le script
        $result = Set-AuthenticodeSignature -FilePath $FilePath -Certificate $Certificate -ErrorAction Stop
        
        if($result.Status -eq "Valid") {
            Write-Host "  Signe: $(Split-Path $FilePath -Leaf)" -F Green
            return $true
        } else {
            Write-Host "  ECHEC: $(Split-Path $FilePath -Leaf) - Status: $($result.Status)" -F Red
            return $false
        }
        
    } catch {
        Write-Host "  ERREUR: $($_.Exception.Message)" -F Red
        return $false
    }
}

# ===============================================
# FONCTION: Signer Tous les Scripts
# ===============================================
function Sign-AllScripts {
    param(
        [string]$RootPath,
        [System.Security.Cryptography.X509Certificates.X509Certificate2]$Certificate
    )
    
    Write-Host "`n=========================================" -F Cyan
    Write-Host "SIGNATURE DE TOUS LES SCRIPTS" -F Cyan
    Write-Host "=========================================`n" -F Cyan
    
    # Trouver tous les scripts .ps1
    $scripts = Get-ChildItem -Path $RootPath -Filter "*.ps1" -File | 
        Where-Object { $_.Name -ne "Sign-Scripts.ps1" }
    
    if($scripts.Count -eq 0) {
        Write-Host "Aucun script trouve dans: $RootPath" -F Yellow
        return
    }
    
    Write-Host "Scripts trouves: $($scripts.Count)" -F Cyan
    
    $signed = 0
    $failed = 0
    
    foreach($script in $scripts) {
        if(Sign-PowerShellScript -FilePath $script.FullName -Certificate $Certificate) {
            $signed++
        } else {
            $failed++
        }
    }
    
    Write-Host "`n=========================================" -F Cyan
    Write-Host "RESULTAT SIGNATURE" -F Cyan
    Write-Host "=========================================`n" -F Cyan
    Write-Host "  Total: $($scripts.Count)" -F Gray
    Write-Host "  Signes: $signed" -F Green
    Write-Host "  Echecs: $failed" -F $(if($failed -eq 0) { "Gray" } else { "Red" })
    Write-Host "`n=========================================" -F Cyan
}

# ===============================================
# FONCTION: Verifier Signatures
# ===============================================
function Verify-Signatures {
    param([string]$RootPath)
    
    Write-Host "`n=========================================" -F Cyan
    Write-Host "VERIFICATION DES SIGNATURES" -F Cyan
    Write-Host "=========================================`n" -F Cyan
    
    $scripts = Get-ChildItem -Path $RootPath -Filter "*.ps1" -File
    
    $valid = 0
    $invalid = 0
    $unsigned = 0
    
    foreach($script in $scripts) {
        $signature = Get-AuthenticodeSignature -FilePath $script.FullName
        
        switch($signature.Status) {
            "Valid" {
                Write-Host "  VALIDE: $($script.Name)" -F Green
                $valid++
            }
            "NotSigned" {
                Write-Host "  NON SIGNE: $($script.Name)" -F Yellow
                $unsigned++
            }
            default {
                Write-Host "  INVALIDE: $($script.Name) - Status: $($signature.Status)" -F Red
                $invalid++
            }
        }
    }
    
    Write-Host "`n=========================================" -F Cyan
    Write-Host "RESULTAT VERIFICATION" -F Cyan
    Write-Host "=========================================`n" -F Cyan
    Write-Host "  Total: $($scripts.Count)" -F Gray
    Write-Host "  Valides: $valid" -F Green
    Write-Host "  Non signes: $unsigned" -F Yellow
    Write-Host "  Invalides: $invalid" -F $(if($invalid -eq 0) { "Gray" } else { "Red" })
    Write-Host "`n=========================================" -F Cyan
}

# ===============================================
# EXECUTION PRINCIPALE
# ===============================================

Write-Host "`n=========================================" -F Cyan
Write-Host "CLOUDFARE - SIGNATURE NUMERIQUE" -F Cyan
Write-Host "=========================================`n" -F Cyan

# Obtenir certificat
$cert = Get-ChildItem Cert:\CurrentUser\My | 
    Where-Object { $_.Subject -like "*CN=CloudFare*" } |
    Select-Object -First 1

if(-not $cert -or $CreateCertificate) {
    $cert = New-CloudFareCertificate
    
    if(-not $cert) {
        Write-Host "`nERREUR: Impossible de creer/obtenir certificat" -F Red
        exit 1
    }
} else {
    Write-Host "Certificat trouve:" -F Green
    Write-Host "  Subject: $($cert.Subject)" -F Gray
    Write-Host "  Thumbprint: $($cert.Thumbprint)" -F Gray
    Write-Host "  Expiration: $($cert.NotAfter)" -F Gray
}

# Signer tous les scripts si demande
if($SignAll) {
    Sign-AllScripts -RootPath $ScriptPath -Certificate $cert
}

# Verifier signatures
Verify-Signatures -RootPath $ScriptPath

Write-Host "`n=========================================" -F Green
Write-Host "SIGNATURE NUMERIQUE COMPLETE!" -F Green
Write-Host "=========================================`n" -F Green

# Exporter informations certificat
$certInfo = @{
    Subject = $cert.Subject
    Thumbprint = $cert.Thumbprint
    NotBefore = $cert.NotBefore
    NotAfter = $cert.NotAfter
    HasPrivateKey = $cert.HasPrivateKey
    SerialNumber = $cert.SerialNumber
}

$certInfo | ConvertTo-Json | Out-File -FilePath (Join-Path $ScriptPath "certificate-info.json") -Encoding UTF8

Write-Host "Informations exportees: certificate-info.json" -F Cyan
Write-Host "`nCertificat pret pour signature!" -F Green
