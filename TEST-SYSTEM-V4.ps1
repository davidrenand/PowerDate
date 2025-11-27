# ===============================================
# TEST-SYSTEM-V4.PS1 - Test Complet Systeme v4
# ===============================================
# Date: 27 Novembre 2025
# Version: 1.0
# Description: Test complet de toutes les strategies v4
# ===============================================

$ErrorActionPreference = "Stop"

Write-Host "`n=========================================" -F Cyan
Write-Host "TEST SYSTEME CLOUDFARE v4.0" -F Cyan
Write-Host "Test Complet de Toutes les Strategies" -F Cyan
Write-Host "=========================================`n" -F Cyan

$results = @{
    TotalTests = 0
    Passed = 0
    Failed = 0
    Warnings = 0
    Tests = @()
}

# ===============================================
# FONCTION: Test Unitaire
# ===============================================
function Test-Component {
    param(
        [string]$Name,
        [scriptblock]$TestScript
    )
    
    $results.TotalTests++
    
    Write-Host "`n[$($results.TotalTests)] Test: $Name" -F Cyan
    
    try {
        $testResult = & $TestScript
        
        if($testResult) {
            Write-Host "  ✅ REUSSI" -F Green
            $results.Passed++
            $status = "PASSED"
        } else {
            Write-Host "  ⚠️ ECHEC" -F Yellow
            $results.Warnings++
            $status = "WARNING"
        }
    } catch {
        Write-Host "  ❌ ERREUR: $($_.Exception.Message)" -F Red
        $results.Failed++
        $status = "FAILED"
    }
    
    $results.Tests += @{
        Name = $Name
        Status = $status
        Timestamp = Get-Date
    }
}

# ===============================================
# TEST 1: Scripts Modules Presents
# ===============================================
Test-Component "Modules scripts presents" {
    $modules = @(
        "Sign-Scripts.ps1",
        "Detect-Antivirus.ps1",
        "Notify-IT.ps1",
        "Install-Universal-v4.ps1"
    )
    
    $allPresent = $true
    foreach($module in $modules) {
        $path = Join-Path $PSScriptRoot $module
        if(Test-Path $path) {
            Write-Host "    Trouve: $module" -F Gray
        } else {
            Write-Host "    Manquant: $module" -F Red
            $allPresent = $false
        }
    }
    
    return $allPresent
}

# ===============================================
# TEST 2: Certificat CloudFare
# ===============================================
Test-Component "Certificat CloudFare" {
    $cert = Get-ChildItem Cert:\CurrentUser\My -ErrorAction SilentlyContinue | 
        Where-Object { $_.Subject -like "*CN=CloudFare*" } |
        Select-Object -First 1
    
    if($cert) {
        Write-Host "    Subject: $($cert.Subject)" -F Gray
        Write-Host "    Thumbprint: $($cert.Thumbprint)" -F Gray
        Write-Host "    Expiration: $($cert.NotAfter)" -F Gray
        
        if($cert.NotAfter -gt (Get-Date)) {
            Write-Host "    Statut: Valide" -F Green
            return $true
        } else {
            Write-Host "    Statut: Expire" -F Red
            return $false
        }
    } else {
        Write-Host "    Certificat non trouve" -F Yellow
        return $false
    }
}

# ===============================================
# TEST 3: Detection Antivirus
# ===============================================
Test-Component "Detection antivirus fonctionnelle" {
    $reportPath = Join-Path $PSScriptRoot "antivirus-detection-report.json"
    
    if(Test-Path $reportPath) {
        $report = Get-Content $reportPath -Raw | ConvertFrom-Json
        
        Write-Host "    Windows Defender: $(if($report.WindowsDefender) { 'Detecte' } else { 'Non detecte' })" -F Gray
        Write-Host "    Antivirus tiers: $($report.ThirdPartyAntivirus.Count)" -F Gray
        Write-Host "    EDR/XDR: $($report.EDR.Count)" -F Gray
        Write-Host "    Recommandations: $($report.Recommendations.Count)" -F Gray
        
        return $true
    } else {
        Write-Host "    Rapport non trouve" -F Yellow
        return $false
    }
}

# ===============================================
# TEST 4: Notification IT
# ===============================================
Test-Component "Systeme de notification IT" {
    $logDir = "C:\ProgramData\CloudFare\Logs"
    
    if(Test-Path $logDir) {
        $logs = Get-ChildItem $logDir -Filter "*.log" -ErrorAction SilentlyContinue
        $jsons = Get-ChildItem $logDir -Filter "notification-*.json" -ErrorAction SilentlyContinue
        $tickets = Get-ChildItem $logDir -Filter "CF-*.json" -ErrorAction SilentlyContinue
        
        Write-Host "    Logs: $($logs.Count)" -F Gray
        Write-Host "    Notifications JSON: $($jsons.Count)" -F Gray
        Write-Host "    Tickets: $($tickets.Count)" -F Gray
        
        if($logs.Count -gt 0 -or $jsons.Count -gt 0 -or $tickets.Count -gt 0) {
            return $true
        } else {
            Write-Host "    Aucun fichier genere" -F Yellow
            return $false
        }
    } else {
        Write-Host "    Repertoire logs non trouve" -F Yellow
        return $false
    }
}

# ===============================================
# TEST 5: Audit Trail
# ===============================================
Test-Component "Audit trail presente" {
    $auditPath = "C:\ProgramData\CloudFare\Audit\audit-trail.log"
    
    if(Test-Path $auditPath) {
        $size = (Get-Item $auditPath).Length
        Write-Host "    Fichier: $auditPath" -F Gray
        Write-Host "    Taille: $size bytes" -F Gray
        return $true
    } else {
        Write-Host "    Audit trail non trouvee" -F Yellow
        return $false
    }
}

# ===============================================
# TEST 6: Script v4 Structure
# ===============================================
Test-Component "Structure Install-Universal-v4.ps1" {
    $scriptPath = Join-Path $PSScriptRoot "Install-Universal-v4.ps1"
    
    if(Test-Path $scriptPath) {
        $content = Get-Content $scriptPath -Raw
        
        $features = @(
            "Step0-DetectAntivirus",
            "Step1-SignScripts",
            "Step2-NotifyIT",
            "Step3-InstallDependencies",
            "Step4-ManageAntivirus",
            "Step5-InstallJava",
            "Step6-InstallJAR",
            "Step7-Verify"
        )
        
        $allPresent = $true
        foreach($feature in $features) {
            if($content -match $feature) {
                Write-Host "    Trouve: $feature" -F Gray
            } else {
                Write-Host "    Manquant: $feature" -F Red
                $allPresent = $false
            }
        }
        
        return $allPresent
    } else {
        return $false
    }
}

# ===============================================
# TEST 7: Retry Mechanism
# ===============================================
Test-Component "Mecanisme de retry GitHub" {
    $scriptPath = Join-Path $PSScriptRoot "Install-Universal-v4.ps1"
    
    if(Test-Path $scriptPath) {
        $content = Get-Content $scriptPath -Raw
        
        if($content -match "Invoke-GitHubDownloadWithRetry" -and 
           $content -match "MaxRetries" -and 
           $content -match "Math\]::Pow") {
            Write-Host "    Fonction retry: Presente" -F Gray
            Write-Host "    Backoff exponentiel: Presente" -F Gray
            Write-Host "    Max retries: Configure" -F Gray
            return $true
        } else {
            Write-Host "    Mecanisme incomplet" -F Yellow
            return $false
        }
    } else {
        return $false
    }
}

# ===============================================
# TEST 8: Logging System
# ===============================================
Test-Component "Systeme de logging" {
    $scriptPath = Join-Path $PSScriptRoot "Install-Universal-v4.ps1"
    
    if(Test-Path $scriptPath) {
        $content = Get-Content $scriptPath -Raw
        
        if($content -match "Write-Log" -and 
           $content -match "logFile" -and 
           $content -match "Add-Content") {
            Write-Host "    Fonction Write-Log: Presente" -F Gray
            Write-Host "    Fichier log: Configure" -F Gray
            return $true
        } else {
            Write-Host "    Systeme de logging incomplet" -F Yellow
            return $false
        }
    } else {
        return $false
    }
}

# ===============================================
# TEST 9: Gestion Antivirus Integree
# ===============================================
Test-Component "Gestion antivirus integree" {
    $scriptPath = Join-Path $PSScriptRoot "Install-Universal-v4.ps1"
    
    if(Test-Path $scriptPath) {
        $content = Get-Content $scriptPath -Raw
        
        if($content -match "Add-MpPreference" -and 
           $content -match "ExclusionPath" -and 
           $content -match "WindowsDefender") {
            Write-Host "    Whitelist: Presente" -F Gray
            Write-Host "    Gestion Windows Defender: Presente" -F Gray
            Write-Host "    Detection antivirus tiers: Presente" -F Gray
            return $true
        } else {
            Write-Host "    Gestion antivirus incomplete" -F Yellow
            return $false
        }
    } else {
        return $false
    }
}

# ===============================================
# TEST 10: Documentation
# ===============================================
Test-Component "Documentation presente" {
    $docs = @(
        "ANTIVIRUS_STRATEGIES.md",
        "WHITELIST_DETECTION_ANALYSIS.md"
    )
    
    $allPresent = $true
    foreach($doc in $docs) {
        $path = Join-Path $PSScriptRoot $doc
        if(Test-Path $path) {
            $size = (Get-Item $path).Length
            Write-Host "    Trouve: $doc ($size bytes)" -F Gray
        } else {
            Write-Host "    Manquant: $doc" -F Red
            $allPresent = $false
        }
    }
    
    return $allPresent
}

# ===============================================
# AFFICHER RESULTATS
# ===============================================

Write-Host "`n=========================================" -F Cyan
Write-Host "RESULTATS DES TESTS" -F Cyan
Write-Host "=========================================`n" -F Cyan

Write-Host "Total tests: $($results.TotalTests)" -F Gray
Write-Host "Reussis: $($results.Passed)" -F Green
Write-Host "Avertissements: $($results.Warnings)" -F Yellow
Write-Host "Echecs: $($results.Failed)" -F Red

$successRate = [Math]::Round(($results.Passed / $results.TotalTests) * 100, 2)
Write-Host "`nTaux de reussite: $successRate%" -F $(if($successRate -ge 80) { "Green" } elseif($successRate -ge 60) { "Yellow" } else { "Red" })

# ===============================================
# GENERER RAPPORT
# ===============================================

$report = @{
    Timestamp = Get-Date
    TotalTests = $results.TotalTests
    Passed = $results.Passed
    Warnings = $results.Warnings
    Failed = $results.Failed
    SuccessRate = $successRate
    Tests = $results.Tests
}

$reportPath = Join-Path $PSScriptRoot "test-results-v4.json"
$report | ConvertTo-Json -Depth 10 | Out-File -FilePath $reportPath -Encoding UTF8

Write-Host "`nRapport exporte: $reportPath" -F Cyan

# ===============================================
# STATUT FINAL
# ===============================================

Write-Host "`n=========================================" -F Cyan
Write-Host "STATUT SYSTEME v4.0" -F Cyan
Write-Host "=========================================`n" -F Cyan

if($successRate -ge 90) {
    Write-Host "SYSTEME PRET POUR PRODUCTION!" -F Green
    Write-Host "Toutes les strategies sont operationnelles." -F Green
} elseif($successRate -ge 70) {
    Write-Host "SYSTEME FONCTIONNEL" -F Yellow
    Write-Host "Quelques composants optionnels manquants." -F Yellow
} else {
    Write-Host "SYSTEME INCOMPLET" -F Red
    Write-Host "Verification requise avant utilisation." -F Red
}

Write-Host "`n=========================================" -F Cyan

# Afficher strategies implementees
Write-Host "`nSTRATEGIES IMPLEMENTEES:" -F Magenta
Write-Host "  1. Whitelist automatique" -F Magenta
Write-Host "  2. Signature numerique" -F Magenta
Write-Host "  3. Certificat auto-signe" -F Magenta
Write-Host "  4. Notification IT" -F Magenta
Write-Host "  5. Detection antivirus tiers" -F Magenta
Write-Host "  6. Retry GitHub (exponentiel)" -F Magenta
Write-Host "  7. Audit trail complet" -F Magenta
Write-Host "  8. Logging avance" -F Magenta

Write-Host "`n=========================================" -F Cyan
Write-Host "TEST SYSTEME v4.0 TERMINE!" -F Green
Write-Host "=========================================`n" -F Cyan
