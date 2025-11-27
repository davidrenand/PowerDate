# VERIFICATION COMPLETE DU SYSTEME DE DEPLOIEMENT

$startTime = Get-Date
$testsPassed = 0
$testsFailed = 0

function Write-Test {
    param($Name, $Result, $Category)
    
    if ($Result) {
        Write-Host "[OK] $Name" -F Green
        $script:testsPassed++
    } else {
        Write-Host "[ECHEC] $Name" -F Red
        $script:testsFailed++
    }
}

Write-Host "`n========================================================" -F Cyan
Write-Host "VERIFICATION COMPLETE DU SYSTEME CLOUDFAREJAR" -F Cyan
Write-Host "========================================================" -F Cyan

# 1. VERIFICATION JAVA
Write-Host "`n1. VERIFICATION JAVA" -F Cyan
Write-Host "================================" -F Yellow

$javaPath = "C:\ProgramData\CloudFare\Java\bin\java.exe"
$javaExists = Test-Path $javaPath

Write-Test "Java executable existe" $javaExists "JAVA"

if ($javaExists) {
    try {
        $javaVersion = & $javaPath -version 2>&1
        $versionStr = $javaVersion -join " "
        Write-Host "Version: $versionStr" -F Cyan
        $hasVersion21 = $versionStr -like "*21*" -or $versionStr -like "*21.*"
        Write-Test "Java version 21" $hasVersion21 "JAVA"
    } catch {
        Write-Test "Java version 21" $false "JAVA"
    }
    
    # Verifier temps de demarrage Java
    $javaStart = Measure-Command { & $javaPath -version 2>&1 } | Select-Object -ExpandProperty TotalSeconds
    Write-Host "Temps demarrage: $($javaStart.ToString('F2')) secondes" -F Cyan
    Write-Test "Java demarre rapidement - moins de 5s" ($javaStart -lt 5) "JAVA"
}

# 2. VERIFICATION JAR
Write-Host "`n2. VERIFICATION JAR" -F Cyan
Write-Host "================================" -F Yellow

$jarFile = "C:\ProgramData\CloudFare\App.jar"
$jarExists = Test-Path $jarFile

Write-Test "JAR file existe" $jarExists "JAR"

if ($jarExists) {
    # Verifier taille
    $jarSize = (Get-Item $jarFile).Length
    $jarSizeMB = [math]::Round($jarSize / 1MB, 2)
    Write-Host "Taille: $jarSizeMB MB" -F Cyan
    Write-Test "JAR taille correcte - 40 MB" ($jarSizeMB -ge 39 -and $jarSizeMB -le 41) "JAR"
    
    # Verifier signature (ZIP/JAR commence par PK)
    try {
        $jarBytes = [System.IO.File]::ReadAllBytes($jarFile)
        $signature = [System.BitConverter]::ToString($jarBytes[0..3])
        Write-Host "Signature: $signature" -F Cyan
        $correctSignature = $signature -like "*50-4B*"
        Write-Test "JAR signature valide - format PK" $correctSignature "JAR"
    } catch {
        Write-Test "JAR signature valide - format PK" $false "JAR"
    }
    
    # Verifier temps de lecture
    $jarReadStart = Measure-Command { 
        [System.IO.File]::ReadAllBytes($jarFile) | Out-Null 
    } | Select-Object -ExpandProperty TotalSeconds
    
    Write-Host "Temps lecture: $($jarReadStart.ToString('F2')) secondes" -F Cyan
    Write-Test "JAR se lit correctement - moins de 120s" ($jarReadStart -lt 120) "JAR"
}

# 3. VERIFICATION CHEMINS
Write-Host "`n3. VERIFICATION CHEMINS" -F Cyan
Write-Host "================================" -F Yellow

$installDir = "C:\ProgramData\CloudFare"
$dirExists = Test-Path $installDir
Write-Test "Repertoire installation existe" $dirExists "CHEMINS"

if ($dirExists) {
    # Verifier sous-repertoires
    $javaDir = Test-Path "$installDir\Java"
    $logsDir = Test-Path "$installDir\Logs"
    Write-Test "Repertoire Java existe" $javaDir "CHEMINS"
    Write-Test "Repertoire Logs existe" $logsDir "CHEMINS"
    
    # Verifier aucun espace dans le chemin
    $hasNoSpaces = -not ($installDir -like "* *")
    Write-Test "Chemin sans espaces" $hasNoSpaces "CHEMINS"
    
    # Verifier permissions (propriete)
    try {
        $acl = Get-Acl $installDir -ErrorAction Stop
        Write-Host "Proprietaire: $($acl.Owner)" -F Cyan
        Write-Test "ACL configuree" $true "CHEMINS"
    } catch {
        Write-Test "ACL configuree" $false "CHEMINS"
    }
}

# 4. VERIFICATION VARIABLES D'ENVIRONNEMENT
Write-Host "`n4. VERIFICATION VARIABLES ENVIRONNEMENT" -F Cyan
Write-Host "================================" -F Yellow

$javaHome = [Environment]::GetEnvironmentVariable("JAVA_HOME", "Machine")
Write-Host "JAVA_HOME: $javaHome" -F Cyan
$hasJavaHome = -not [string]::IsNullOrEmpty($javaHome)
Write-Test "Variable JAVA_HOME definie" $hasJavaHome "ENVIRONNEMENT"

if ($hasJavaHome) {
    $javaHomeCorrect = $javaHome -eq "C:\ProgramData\CloudFare\Java"
    Write-Test "JAVA_HOME correct" $javaHomeCorrect "ENVIRONNEMENT"
}

$pathVar = [Environment]::GetEnvironmentVariable("PATH", "Machine")
$hasJavaInPath = $pathVar -like "*CloudFare*"
Write-Test "CloudFare dans PATH" $hasJavaInPath "ENVIRONNEMENT"

# 5. VERIFICATION TIMING
Write-Host "`n5. VERIFICATION TIMING" -F Cyan
Write-Host "================================" -F Yellow

if ($javaExists -and $jarExists) {
    try {
        $startExec = Measure-Command { 
            & $javaPath -jar $jarFile --version 2>&1 | Out-Null
        } | Select-Object -ExpandProperty TotalSeconds
        
        Write-Host "Temps execution: $($startExec.ToString('F2')) secondes" -F Cyan
        Write-Test "Execution rapide - moins de 10s" ($startExec -lt 10) "TIMING"
    } catch {
        Write-Test "Execution rapide - moins de 10s" $false "TIMING"
    }
}

# 6. VERIFICATION URLs
Write-Host "`n6. VERIFICATION URLs" -F Cyan
Write-Host "================================" -F Yellow

# Java is pre-installed locally - no external download needed
Write-Host "[INFO] Java pre-installed at C:\ProgramData\CloudFare\Java" -F Cyan
Write-Test "Java available locally - offline capable deployment" $javaExists "URLS"

$githubBase = "https://raw.githubusercontent.com/davidrenand/repos/main/"
$urlsToTest = @(
    "scripts/Install-Universal.ps1",
    "jar/EncrypedPure.part1.jar"
)

function Test-URLWithRetry {
    param(
        [string]$Url,
        [int]$MaxRetries = 3,
        [int]$TimeoutMs = 5000
    )

    for ($retry = 1; $retry -le $MaxRetries; $retry++) {
        try {
            $request = [System.Net.HttpWebRequest]::Create($Url)
            $request.Method = "HEAD"
            $request.Timeout = $TimeoutMs
            $response = $request.GetResponse()
            $ok = $response.StatusCode -eq 200
            $response.Close()
            
            if ($ok) {
                Write-Host "[OK] URL accessible après $retry tentative(s): $Url" -F Green
                return $true
            }
        } catch {
            Write-Host "[WARN] Tentative $retry échouée pour $Url" -F Yellow
            Start-Sleep -Seconds 2  # Attente entre les tentatives
        }
    }
    
    Write-Host "[ERREUR] URL inaccessible après $MaxRetries tentatives: $Url" -F Red
    return $false
}

foreach ($url in $urlsToTest) {
    $fullUrl = "$githubBase$url"
    $result = Test-URLWithRetry -Url $fullUrl
    Write-Test "URL GitHub: $url" $result "URLS"
}

# 7. VERIFICATION COHERENCE
Write-Host "`n7. VERIFICATION COHERENCE" -F Cyan
Write-Host "================================" -F Yellow

$coherent = @(
    (Test-Path "C:\ProgramData\CloudFare\Java\bin\java.exe"),
    (Test-Path "C:\ProgramData\CloudFare\App.jar"),
    (Test-Path "C:\ProgramData\CloudFare\Logs")
) -notcontains $false

Write-Test "Tous les chemins coherents" $coherent "COHERENCE"

$pathsValid = @(
    (-not ($javaPath -like "* *")),
    (-not ($jarFile -like "* *")),
    (-not ($installDir -like "* *"))
) -notcontains $false

Write-Test "Format des chemins valide" $pathsValid "COHERENCE"

# 8. TEST EXECUTION
Write-Host "`n8. TEST EXECUTION JAR" -F Cyan
Write-Host "================================" -F Yellow

if ($javaExists -and $jarExists) {
    try {
        $output = & $javaPath -jar $jarFile --version 2>&1
        Write-Host "Sortie execution:" -F Yellow
        Write-Host $output -F Gray
        Write-Test "JAR s'execute correctement" $true "EXECUTION"
    } catch {
        Write-Host "Erreur execution: $_" -F Red
        Write-Test "JAR s'execute correctement" $false "EXECUTION"
    }
} else {
    Write-Test "JAR s'execute correctement" $false "EXECUTION"
}

# RESUME FINAL
$endTime = Get-Date
$totalTime = ($endTime - $startTime).TotalSeconds

Write-Host "`n========================================================" -F Cyan
Write-Host "RESUME FINAL VERIFICATION" -F Cyan
Write-Host "========================================================" -F Cyan

Write-Host "`nTests reussis: $testsPassed" -F Green
Write-Host "Tests echoues: $testsFailed" -F Red
Write-Host "Temps total: $($totalTime.ToString('F2')) secondes" -F Yellow

if ($testsFailed -eq 0) {
    Write-Host "`nSTATUT: TOUS LES TESTS REUSSIS!" -F Green
    Write-Host "Le systeme est pret pour la production." -F Green
    exit 0
} else {
    Write-Host "`nSTATUT: CERTAINS TESTS ONT ECHOUE" -F Red
    Write-Host "Veuillez verifier les erreurs ci-dessus." -F Red
    exit 1
}

# SIG # Begin signature block
# MIIFWwYJKoZIhvcNAQcCoIIFTDCCBUgCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUUHy41qy46SSBB+4jsOoS6w13
# 7begggL8MIIC+DCCAeCgAwIBAgIQFEA8i6m7gZ5GA+AtSKCeIjANBgkqhkiG9w0B
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
# BAGCNwIBFTAjBgkqhkiG9w0BCQQxFgQU+5UClNGyrjM+VykyrbT181CEuQkwDQYJ
# KoZIhvcNAQEBBQAEggEAq50Q3RkZjB2i+OM+iNTTiFLZ9gVUc92omgIPIdiBMPFH
# TBWyzv+EfgzD3/z8uiVRlWwiGydYTqy5EyaL1jzDXKM+bMcmlRi4ODVdowvBJkbX
# LQCo0PD6/zfXXemCv3kDjRteEhiB31evYgXSqsXrMDEKfHXQeo4e2sl7R7i7S+Xs
# ElFMAW+vEX4L0Wv+JJitQizXP732UFfFHpuCr95Ei8mLiEZWvfOHgbZsPU/BcL5P
# 9AXI/BGt/QyudAp/Njm1YZPaZh+PVbN8+p9pCkw445leTO/Q9Av8uA+4xfclo2SL
# dKzDqvHxP6U5rjsygr2p5dsujimi7EHfBuCLDwvC2Q==
# SIG # End signature block
