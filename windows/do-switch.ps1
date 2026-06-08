# ============================================================
#  do-switch.ps1  (must be run with admin privileges)
#  -Mode ubuntu    : set UEFI BootNext to Ubuntu + reboot
#  -Mode windows   : clear any pending BootNext (no reboot)
#  -Mode fixclock  : set Windows to treat RTC as UTC
#                    (one-time dual-boot clock fix)
# ============================================================

param(
    [Parameter(Mandatory = $true)]
    [ValidateSet('ubuntu','windows','fixclock')]
    [string]$Mode
)

$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Windows.Forms

function Show-Box {
    param(
        [string]$Title, [string]$Message,
        [ValidateSet('Info','Warn','Error')]
        [string]$Kind = 'Info'
    )
    $icon = switch ($Kind) {
        'Info'  { [System.Windows.Forms.MessageBoxIcon]::Information }
        'Warn'  { [System.Windows.Forms.MessageBoxIcon]::Warning }
        'Error' { [System.Windows.Forms.MessageBoxIcon]::Error }
    }
    [System.Windows.Forms.MessageBox]::Show(
        $Message, $Title,
        [System.Windows.Forms.MessageBoxButtons]::OK, $icon) | Out-Null
}

# 0. Must be admin
$isAdmin = ([Security.Principal.WindowsPrincipal] `
    [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(
    [Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Show-Box 'Need admin' 'Administrator privilege required. Trigger from the tray menu (it will prompt UAC).' 'Error'
    exit 1
}

# Mode = fixclock: one-time registry fix for dual-boot clock drift
if ($Mode -eq 'fixclock') {
    try {
        $key = 'HKLM:\SYSTEM\CurrentControlSet\Control\TimeZoneInformation'
        Set-ItemProperty -Path $key -Name 'RealTimeIsUniversal' -Value 1 -Type DWord -Force
        $val = (Get-ItemProperty -Path $key -Name 'RealTimeIsUniversal').RealTimeIsUniversal

        $resyncMsg = ''
        try {
            Start-Service w32time -ErrorAction SilentlyContinue
            & w32tm /config /update 2>&1 | Out-Null
            $r2 = & w32tm /resync /force 2>&1 | Out-String
            $resyncMsg = "`n`nTime sync triggered: $($r2.Trim())"
        } catch {
            $resyncMsg = "`n`nTime sync skipped: $($_.Exception.Message)"
        }

        Show-Box 'Done' "Dual-boot clock fix applied.`n`nRegistry key RealTimeIsUniversal = $val`n`nWindows will now read the hardware clock as UTC (matching Ubuntu's default). This is a one-time fix that persists across all future reboots - no more time drift when switching between systems.$resyncMsg" 'Info'
        exit 0
    } catch {
        Show-Box 'Fix failed' "Could not write registry: $($_.Exception.Message)" 'Error'
        exit 7
    }
}

# 1. UEFI check (ubuntu/windows modes)
$probe = & bcdedit /enum "{fwbootmgr}" 2>&1 | Out-String
if ($LASTEXITCODE -ne 0 -or $probe -notmatch 'fwbootmgr') {
    Show-Box 'UEFI check failed' "System does not appear to be UEFI. This tool only supports UEFI.`n`n$probe" 'Error'
    exit 2
}

# Mode = windows: clear bootsequence (cancel pending switch), no reboot
if ($Mode -eq 'windows') {
    & bcdedit /deletevalue "{fwbootmgr}" bootsequence 2>&1 | Out-Null
    Show-Box 'Done' "Any pending one-time switch has been cleared. Next boot will follow the default boot order (Windows)." 'Info'
    exit 0
}

# Mode = ubuntu: enumerate firmware entries and find Ubuntu
$output = & bcdedit /enum firmware 2>&1 | Out-String
if ($LASTEXITCODE -ne 0) {
    Show-Box 'bcdedit failed' $output 'Error'
    exit 3
}

$blocks = $output -split "(?:\r?\n){2,}"
$ubuntuGuid = $null
$ubuntuDesc = ''

# Locale-agnostic: find block by \EFI\ubuntu\ path or 'ubuntu'/'GRUB' description.
# (Using \uXXXX escape for the localized Chinese 'description' field name keeps
#  this file pure ASCII so PowerShell 5 can parse it without a BOM.)
foreach ($block in $blocks) {
    $isUbuntu = $false
    if ($block -match '(?i)\\EFI\\ubuntu\\') {
        $isUbuntu = $true
    } elseif ($block -match '(?im)^\s*\S+\s+ubuntu\s*$') {
        $isUbuntu = $true
    } elseif ($block -match '(?im)^\s*\S+\s+GRUB\s*$') {
        $isUbuntu = $true
    }
    if (-not $isUbuntu) { continue }

    $guidMatch = [regex]::Match(
        $block,
        '\{[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}\}')
    if (-not $guidMatch.Success) { continue }

    $ubuntuGuid = $guidMatch.Value
    $descMatch = [regex]::Match($block, '(?im)^\s*(?:description|描述)\s+(.+?)\s*$')
    $ubuntuDesc = if ($descMatch.Success) { $descMatch.Groups[1].Value.Trim() } else { 'Ubuntu' }
    break
}

if (-not $ubuntuGuid) {
    $dump = Join-Path $env:TEMP 'bcdedit-firmware-dump.txt'
    $output | Set-Content -Path $dump -Encoding UTF8
    Show-Box 'Ubuntu entry not found' `
        "No Ubuntu/GRUB entry found in UEFI firmware boot manager.`n`nFull bcdedit output saved to:`n$dump" 'Error'
    exit 4
}

# Apply: set BootNext via bootsequence on {fwbootmgr}
try {
    $r = & bcdedit /set "{fwbootmgr}" bootsequence "$ubuntuGuid" 2>&1 | Out-String
    if ($LASTEXITCODE -ne 0) { throw $r }
} catch {
    Show-Box 'Failed to set boot entry' $_.Exception.Message 'Error'
    exit 5
}

# Reboot in 5s
$comment = "Next boot: $ubuntuDesc (once). Rebooting in 5 seconds..."
try {
    & shutdown /r /t 5 /c $comment 2>&1 | Out-Null
} catch {
    Show-Box 'Reboot failed' "Boot entry set OK, but reboot command failed: $($_.Exception.Message)`nPlease reboot manually." 'Warn'
    exit 6
}

exit 0
