' BootFlip.vbs - silent launcher for BootFlip.ps1
Option Explicit

Dim shell, fso, scriptDir, ps1Path, cmd
Set shell = CreateObject("WScript.Shell")
Set fso   = CreateObject("Scripting.FileSystemObject")

scriptDir = fso.GetParentFolderName(WScript.ScriptFullName)
ps1Path   = scriptDir & "\BootFlip.ps1"

If Not fso.FileExists(ps1Path) Then
    MsgBox "BootFlip.ps1 not found." & vbCrLf & "Expected at: " & ps1Path, _
        vbCritical, "BootFlip - launch failed"
    WScript.Quit 1
End If

cmd = "powershell.exe -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File """ & ps1Path & """"
shell.Run cmd, 0, False
