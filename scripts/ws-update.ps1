# ==============================================================================
# Packer Windows Update Script with Verbose Log Tailing
# ==============================================================================

$ErrorActionPreference = 'Stop'
Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process -Force

$LogPath = "C:\Windows\Temp\packer-update-status.log"

# Clean old logs if present
if (Test-Path $LogPath) { Remove-Item $LogPath -Force }

Write-Output "==> Preparing Windows Update Services..."
Get-Service -Name wuauserv, bits | Set-Service -StartupType Automatic
Start-Service -Name wuauserv, bits -ErrorAction SilentlyContinue

# Ensure PSWindowsUpdate is available
if (-not (Get-Module -ListAvailable -Name PSWindowsUpdate)) {
    Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force -ErrorAction Stop
    Install-Module -Name PSWindowsUpdate -Force -Scope AllUsers -ErrorAction Stop
}

# 1. Create task payload using -Verbose to log step-by-step update installation
$UpdateScript = @"
Import-Module PSWindowsUpdate
Add-WUServiceManager -ServiceID '7971f918-a847-4430-9279-4a52d1efe18d' -Confirm:`$false -ErrorAction SilentlyContinue

# Using -Verbose sends step-by-step download/install progress to the log file
Get-WindowsUpdate -MicrosoftUpdate -AcceptAll -Install -IgnoreReboot -Verbose 4>&1 | Out-File -FilePath '$LogPath' -Encoding UTF8 -Append
"@

$TaskScriptPath = "C:\Windows\Temp\Run-Updates.ps1"
$UpdateScript | Out-File -FilePath $TaskScriptPath -Encoding UTF8 -Force

# 2. Register SYSTEM scheduled task
$TaskName = "PackerWindowsUpdateTask"
$Action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-NoProfile -ExecutionPolicy Bypass -File `"$TaskScriptPath`""
$Principal = New-ScheduledTaskPrincipal -UserId "NT AUTHORITY\SYSTEM" -RunLevel Highest
$Settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries

Register-ScheduledTask -TaskName $TaskName -Action $Action -Principal $Principal -Settings $Settings -Force | Out-Null

# 3. Start task
Write-Output "==> Starting Windows Updates (Streaming Verbose Status)..."
Start-ScheduledTask -TaskName $TaskName

# Wait briefly for log file creation
$timeout = 0
while (-not (Test-Path $LogPath) -and $timeout -lt 30) {
    Start-Sleep -Seconds 2
    $timeout += 2
}

# 4. Tail log file in real-time so Packer prints progress live to screen
if (Test-Path $LogPath) {
    $LogReader = Get-Content -Path $LogPath -Wait -Tail 0

    # Loop log tailing while scheduled task is running
    foreach ($Line in $LogReader) {
        Write-Output " [WU Status] $Line"

        if ((Get-ScheduledTask -TaskName $TaskName).State -ne 'Running') {
            break
        }
    }
}

# Cleanup
Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false -ErrorAction SilentlyContinue
Remove-Item -Path $TaskScriptPath -Force -ErrorAction SilentlyContinue

Write-Output "==> Windows Updates execution finished."