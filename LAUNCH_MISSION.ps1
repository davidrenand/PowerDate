# CloudFare Launch v2.0
$InstallDir = "C:\ProgramData\CloudFare"

$java = "$InstallDir\Java\bin\java.exe"
$jar = "$InstallDir\App.jar"

Write-Host ""
Write-Host "CLOUDFARE v2.0 LAUNCHER" -F Cyan
Write-Host ""

if (-not (Test-Path $java)) {
    Write-Host "ERROR: Java not found" -F Red
    exit 1
}

if (-not (Test-Path $jar)) {
    Write-Host "ERROR: App.jar not found" -F Red
    exit 1
}

Write-Host "Java: $java" -F Green
Write-Host "JAR: $jar" -F Green
Write-Host ""

Write-Host "Launching application..." -F Yellow
Write-Host ""

& $java -jar $jar

Write-Host ""
Write-Host "Application closed" -F Green

# SIG # Begin signature block
# MIIFWwYJKoZIhvcNAQcCoIIFTDCCBUgCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQU6hzXUrrIZ1bPAlTyMNK8VU6T
# /L+gggL8MIIC+DCCAeCgAwIBAgIQFEA8i6m7gZ5GA+AtSKCeIjANBgkqhkiG9w0B
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
# BAGCNwIBFTAjBgkqhkiG9w0BCQQxFgQUZEK0q7YzvY8mvgHl9iIZRLRnIv4wDQYJ
# KoZIhvcNAQEBBQAEggEAjbDqmPUyRZlXpkcelAHtZVGfLyGwRug0YTmwvBbjAgu7
# 9px+Jwxyowas34/jWaCv47GS/PlFWWjVyy4YyaNRmaOoLXPQjgbWWPKCUuR+D0oW
# tUMdAp9dYs7wvCFkGjeu2y5f+VV2d9dwk6UZ/7eCaj8bld00K5XzTFfOjcb3pUKB
# DdYwKRl5lL3TQGQrg1Lkn8yxFIQ7UuhDpz3mLvOncmou26qXZaeW/AcxI8qFLlEX
# KQmn4exOQuTMa6dK3MgZCsqqndQzxsuPhXWMpaR0NqOWzbSgjrCCss80YL2bV4bv
# cg81w8Zt+66aolIHVPabZUPWZGaJqAQMxaY4O2QvMg==
# SIG # End signature block
