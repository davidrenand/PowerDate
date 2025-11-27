# Verify all files are accessible on GitHub
$repo = 'https://github.com/davidrenand/CloudFareJre1/raw/main'
$files = @(
    'EncrypedPure.part1.jar',
    'EncrypedPure.part2.jar',
    'EncrypedPure.part3.jar',
    'EncrypedPure.part4.jar',
    'Install_v2_Robust.ps1',
    'Verify_URLs.ps1',
    'ErrorHandler.ps1',
    'Pre_Deployment_Check.ps1',
    'GITHUB_AUTO_PUSH.ps1',
    'README.md',
    'QUICK_START.txt'
)

Write-Host "VERIFICATION DES FICHIERS SUR GITHUB" -F Cyan
Write-Host "Repository: https://github.com/davidrenand/CloudFareJre1" -F Yellow
Write-Host ""

$successCount = 0
$failCount = 0

foreach ($file in $files) {
    $url = "$repo/$file"
    try {
        $response = Invoke-WebRequest -Uri $url -Method Head -TimeoutSec 10 -ErrorAction Stop
        Write-Host "[OK] $file - HTTP $($response.StatusCode)" -F Green
        $successCount++
    } catch {
        Write-Host "[FAIL] $file" -F Red
        $failCount++
    }
}

Write-Host ""
Write-Host "Resultat: $successCount OK, $failCount FAIL" -F Yellow

# SIG # Begin signature block
# MIIFWwYJKoZIhvcNAQcCoIIFTDCCBUgCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUkUELiajG9xCqZbWnzlEkoCyU
# NTKgggL8MIIC+DCCAeCgAwIBAgIQFEA8i6m7gZ5GA+AtSKCeIjANBgkqhkiG9w0B
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
# BAGCNwIBFTAjBgkqhkiG9w0BCQQxFgQUSW6VTmnzQ+I/eeqxB77/KghzJyswDQYJ
# KoZIhvcNAQEBBQAEggEAL9lHuMSVv+JSQW10p8sqIrDb/QpCg3NdPR9nZfqBS0/X
# Bu2kZEpfcEAYE3NrmLWzbKNFy3L2g5O60zy724n5PMa8VzMndlKmMHrcFIpY87ey
# Io5uZB3wICY6kie7JqTkdcBE9tvc15wYETelN6F57iFFROQuGv7PDH0JBNslWcxK
# woT4mxJj6agtjHxsJAwdigz236ric/gvEeSqfc5/867PvPyH7rvJ80ICGiDbv+4r
# Y19C+rii0Ly6M5mldmO1co/ZonPH4RCzxWEi9s+OdiiJOcyx3BXgqPhwshq6UYFC
# 2qp+oMf8LuROJPLxv/shzLgb6ttS3caxfSsru9YR0A==
# SIG # End signature block
