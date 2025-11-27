# CloudFare v4.0 - 100% SILENT Installation (PowerShell)
# No UI, no prompts, no interaction required

$ErrorActionPreference = "SilentlyContinue"
$ProgressPreference = "SilentlyContinue"

# Check if running as admin
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")
if (-not $isAdmin) {
    exit 1
}

$msiPath = Join-Path $PSScriptRoot "CloudFare-Setup-v4.0.msi"
if (-not (Test-Path $msiPath)) {
    exit 1
}

# Run MSI silently
$process = Start-Process msiexec.exe -ArgumentList "/i `"$msiPath`" /qn /norestart /l*v `"$env:TEMP\CloudFare-Silent.log`" ALLUSERS=1" -Wait -PassThru

exit $process.ExitCode
