# Download-WithRetry.ps1
# Enhanced Download Function with Retry Mechanism

function Invoke-FileDownloadWithRetry {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Url,
        
        [Parameter(Mandatory=$true)]
        [string]$DestinationPath,
        
        [int]$MaxRetries = 3,
        [int]$RetryDelaySeconds = 5
    )

    $logFile = Join-Path $env:TEMP "CloudFare_Download.log"

    function Write-Log {
        param([string]$Message)
        $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        Add-Content -Path $logFile -Value "[$timestamp] $Message"
        Write-Host $Message
    }

    Write-Log "Starting download: $Url"
    Write-Log "Destination: $DestinationPath"

    for ($retry = 1; $retry -le $MaxRetries; $retry++) {
        try {
            $webClient = New-Object System.Net.WebClient
            $webClient.Headers.Add("user-agent", "CloudFare/2.0")
            
            # Create destination directory if it doesn't exist
            $destDir = Split-Path $DestinationPath
            if (-not (Test-Path $destDir)) {
                New-Item -Path $destDir -ItemType Directory -Force | Out-Null
            }

            $webClient.DownloadFile($Url, $DestinationPath)
            
            Write-Log "Download successful after $retry attempt(s)"
            return $true
        }
        catch {
            Write-Log "Download attempt $retry failed: $_"
            
            if ($retry -lt $MaxRetries) {
                Write-Log "Waiting $RetryDelaySeconds seconds before retry..."
                Start-Sleep -Seconds $RetryDelaySeconds
            }
        }
        finally {
            if ($webClient) { $webClient.Dispose() }
        }
    }

    Write-Log "CRITICAL: Download failed after $MaxRetries attempts"
    return $false
}

# Export the function for use in other scripts
Export-ModuleMember -Function Download-WithRetry
# SIG # Begin signature block
# MIIFWwYJKoZIhvcNAQcCoIIFTDCCBUgCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUHGn332aR1w49G5oltga/pPat
# rHagggL8MIIC+DCCAeCgAwIBAgIQFEA8i6m7gZ5GA+AtSKCeIjANBgkqhkiG9w0B
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
# BAGCNwIBFTAjBgkqhkiG9w0BCQQxFgQUAnudpn2ivkG+3bMYQNnm1Zcyy90wDQYJ
# KoZIhvcNAQEBBQAEggEAEr1qM8y+qe/8BAAYVuGkXRE6zWR/oBGsoJDxH1lXGeOz
# cxZmOkQ9vY6/0kO9EOKD5jl9Bp/eSVOJZAmuetL1vl907J9ezRssw/g8q54OMnVQ
# a0S5gtOOOgot3UacWN2bNQdmvkqQHf1aQ8Pb0WDWe4XkeZIJLrpJCzwvViW68P8S
# DxhqkqXgZXskDR215FG1eAiW7RSyeXSGIGXTgvHnxOicZZUH7UaPKlBxZZGDI10i
# n+s9vGhEEXpuboPGrhYiHdbVR52k7pe58Olhfm7FbMY9FoQ6wBpizr89ZQIcF50L
# bRKfDtzaVJwj+3jUzNarpmuFZGmbvT0jxkU2WPBHsw==
# SIG # End signature block
