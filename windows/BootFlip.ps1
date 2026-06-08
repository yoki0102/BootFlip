# ============================================================
#  BootFlip.ps1
#  Tray program: bottom-right icon -> menu -> reboot into Ubuntu
# ============================================================

# --- Single-instance guard ---------------------------------------------------
$mutexName  = "BootFlip-Tray-SingleInstance-$([System.Environment]::UserName)"
$createdNew = $false
try {
    $script:_appMutex = New-Object System.Threading.Mutex($true, $mutexName, [ref]$createdNew)
} catch [System.Threading.AbandonedMutexException] {
    $createdNew = $true
}
if (-not $createdNew) { exit 0 }
# -----------------------------------------------------------------------------

# Hide console window
try {
    Add-Type -Name Win -Namespace Native -MemberDefinition @"
[System.Runtime.InteropServices.DllImport("kernel32.dll")]
public static extern System.IntPtr GetConsoleWindow();
[System.Runtime.InteropServices.DllImport("user32.dll")]
public static extern bool ShowWindow(System.IntPtr hWnd, int nCmdShow);
"@
    $hwnd = [Native.Win]::GetConsoleWindow()
    if ($hwnd -ne [System.IntPtr]::Zero) {
        [Native.Win]::ShowWindow($hwnd, 0) | Out-Null
    }
} catch {}

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

$ScriptDir  = Split-Path -Parent $MyInvocation.MyCommand.Definition
$IconPath   = Join-Path $ScriptDir 'bootflip.ico'
$WorkerPath = Join-Path $ScriptDir 'do-switch.ps1'

$tray = New-Object System.Windows.Forms.NotifyIcon
if (Test-Path $IconPath) {
    $tray.Icon = New-Object System.Drawing.Icon($IconPath)
} else {
    $tray.Icon = [System.Drawing.SystemIcons]::Application
}
$tray.Text    = 'BootFlip'
$tray.Visible = $true

$menu = New-Object System.Windows.Forms.ContextMenuStrip
$itemUbuntu  = $menu.Items.Add('Switch to Ubuntu')
$itemWindows = $menu.Items.Add('Switch to Windows')
[void]$menu.Items.Add('-')
$itemExit    = $menu.Items.Add('Exit')
$tray.ContextMenuStrip = $menu

function Invoke-Worker {
    param(
        [ValidateSet('ubuntu','windows')]
        [string]$Target
    )

    if ($Target -eq 'ubuntu') {
        $msg = "This will reboot the computer immediately. Any unsaved work will be lost.`n`nContinue?"
        $title = 'Switch to Ubuntu'
    } else {
        $msg = "This will cancel any pending switch and keep Windows as the next boot.`n`nNo reboot will happen.`n`nContinue?"
        $title = 'Switch to Windows'
    }

    $confirm = [System.Windows.Forms.MessageBox]::Show(
        $msg, $title,
        [System.Windows.Forms.MessageBoxButtons]::OKCancel,
        [System.Windows.Forms.MessageBoxIcon]::Warning,
        [System.Windows.Forms.MessageBoxDefaultButton]::Button2
    )
    if ($confirm -ne [System.Windows.Forms.DialogResult]::OK) { return }

    if (-not (Test-Path $WorkerPath)) {
        [System.Windows.Forms.MessageBox]::Show(
            "do-switch.ps1 not found at:`n$WorkerPath",
            'Error','OK','Error') | Out-Null
        return
    }

    $argLine = "-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File `"$WorkerPath`" -Mode $Target"
    try {
        Start-Process -FilePath 'powershell.exe' -ArgumentList $argLine -Verb RunAs -ErrorAction Stop | Out-Null
    } catch {
        [System.Windows.Forms.MessageBox]::Show(
            "Operation cancelled: $($_.Exception.Message)",
            'Cancelled','OK','Information') | Out-Null
    }
}

$itemUbuntu.Add_Click({   Invoke-Worker -Target 'ubuntu'   })
$itemWindows.Add_Click({  Invoke-Worker -Target 'windows'  })

$itemExit.Add_Click({
    $tray.Visible = $false
    $tray.Dispose()
    [System.Windows.Forms.Application]::Exit()
})

$tray.Add_MouseClick({
    param($sender, $e)
    if ($e.Button -eq [System.Windows.Forms.MouseButtons]::Left) {
        $m = $tray.GetType().GetMethod('ShowContextMenu',
            [System.Reflection.BindingFlags]::Instance -bor `
            [System.Reflection.BindingFlags]::NonPublic)
        $m.Invoke($tray, $null)
    }
})

$tray.BalloonTipTitle = 'BootFlip'
$tray.BalloonTipText  = 'Running in the background. Click the tray icon to choose.'
$tray.BalloonTipIcon  = [System.Windows.Forms.ToolTipIcon]::Info
$tray.ShowBalloonTip(3000)

[System.Windows.Forms.Application]::Run()
