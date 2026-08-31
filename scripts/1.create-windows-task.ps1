$ErrorActionPreference = "Stop"

$TaskName   = "PackerWindowsUpdateTask"
$ScriptPath = "C:\Windows\Temp\windows-update-task.ps1"
$LogFile    = "C:\Windows\Temp\windows-update-task.log"

Write-Output "============================================================"
Write-Output "[START] Creating Windows Update Scheduled Task"
Write-Output "============================================================"
Write-Output "[INFO] Current user : $(whoami)"
Write-Output "[INFO] Started      : $(Get-Date)"
Write-Output "[INFO] Task name    : $TaskName"
Write-Output "[INFO] Script path  : $ScriptPath"
Write-Output "[INFO] Log file     : $LogFile"

# ------------------------------------------------------------
# Check script exists
# ------------------------------------------------------------

Write-Output ""
Write-Output "[CHECK] Checking whether Windows Update script exists..."

if (-not (Test-Path $ScriptPath)) {
    Write-Error "[ERROR] Windows Update script not found at $ScriptPath"
    throw "Windows Update Script not found at $ScriptPath"
}

Write-Output "[OK] Windows Update script found."

# ------------------------------------------------------------
# Remove existing task
# ------------------------------------------------------------

Write-Output ""
Write-Output "[CHECK] Checking whether scheduled task already exists..."

$ExistingTask = Get-ScheduledTask `
    -TaskName $TaskName `
    -ErrorAction SilentlyContinue

if ($null -ne $ExistingTask) {

    Write-Output "[INFO] Existing task '$TaskName' found."
    Write-Output "[INFO] Removing existing task..."

    Unregister-ScheduledTask `
        -TaskName $TaskName `
        -Confirm:$false

    Write-Output "[OK] Existing task removed."
}
else {
    Write-Output "[OK] Existing task not found."
}

# ------------------------------------------------------------
# Create Scheduled Task action
# ------------------------------------------------------------

Write-Output ""
Write-Output "[TASK] Creating Scheduled Task action..."

$Arguments = "-NoProfile -ExecutionPolicy Bypass -File `"$ScriptPath`""

$Action = New-ScheduledTaskAction `
    -Execute "PowerShell.exe" `
    -Argument $Arguments

Write-Output "[OK] Scheduled Task action created."

# ------------------------------------------------------------
# Create SYSTEM principal
# ------------------------------------------------------------

Write-Output ""
Write-Output "[TASK] Creating SYSTEM security principal..."

$Principal = New-ScheduledTaskPrincipal `
    -UserId "SYSTEM" `
    -LogonType ServiceAccount `
    -RunLevel Highest

Write-Output "[OK] SYSTEM principal created."
Write-Output "[INFO] User     : SYSTEM"
Write-Output "[INFO] RunLevel : Highest"

# ------------------------------------------------------------
# Create trigger
# ------------------------------------------------------------

$TriggerTime = (Get-Date).AddMinutes(1)

Write-Output ""
Write-Output "[TASK] Creating task trigger..."
Write-Output "[INFO] Trigger time: $TriggerTime UTC"

$Trigger = New-ScheduledTaskTrigger `
    -Once `
    -At $TriggerTime

Write-Output "[OK] Task trigger created."

# ------------------------------------------------------------
# Task Settings
# ------------------------------------------------------------
$Settings = New-ScheduledTaskSettingsSet -StartWhenAvailable -RestartCount 10 -RestartInterval (New-TimeSpan -Minutes 1)
# ------------------------------------------------------------
# Register task
# ------------------------------------------------------------

Write-Output ""
Write-Output "[TASK] Registering Scheduled Task..."

Register-ScheduledTask `
    -TaskName $TaskName `
    -Action $Action `
    -Trigger $Trigger `
    -Principal $Principal `
    -Settings $Settings `
    -Description "Packer Windows Update Task running as SYSTEM"

Write-Output "[OK] Scheduled Task registered successfully."

# ------------------------------------------------------------
# Verify task configuration
# ------------------------------------------------------------

Write-Output ""
Write-Output "[VERIFY] Reading Scheduled Task configuration..."

$Task = Get-ScheduledTask -TaskName $TaskName

Write-Output "[VERIFY] Task Name : $($Task.TaskName)"
Write-Output "[VERIFY] State     : $($Task.State)"
Write-Output "[VERIFY] User      : $($Task.Principal.UserId)"
Write-Output "[VERIFY] LogonType : $($Task.Principal.LogonType)"
Write-Output "[VERIFY] RunLevel  : $($Task.Principal.RunLevel)"

# ------------------------------------------------------------
# Start task
# ------------------------------------------------------------

Write-Output ""
Write-Output "[TASK] Starting Scheduled Task..."

Start-ScheduledTask -TaskName $TaskName

Write-Output "[OK] Scheduled Task started successfully."

# ------------------------------------------------------------
# Final information
# ------------------------------------------------------------

Write-Output ""
Write-Output "============================================================"
Write-Output "[DONE] Windows Update Scheduled Task created and started."
Write-Output "============================================================"

# ------------------------------------------------------------
# Wait for log file
# ------------------------------------------------------------

Write-Output "[INFO] Waiting for log file..."

$Timeout = 60
$Elapsed = 0

while (-not (Test-Path $LogFile)) {

    Start-Sleep -Seconds 1
    $Elapsed++

    if ($Elapsed -ge $Timeout) {
        throw "Timed out waiting for log file: $LogFile"
    }
}

Write-Output "[OK] Log file detected."
Write-Output ""

# ------------------------------------------------------------
# Tail log
# ------------------------------------------------------------
$CompletionMarker = "[INFO] Stopping PowerShell transcript..."
$LastLine = 0

while ($true) {

    if (Test-Path $LogFile) {

        $Lines = Get-Content $LogFile

        if ($Lines.Count -gt $LastLine) {

            $NewLines = $Lines[$LastLine..($Lines.Count - 1)]

            foreach ($Line in $NewLines) {
                Write-Output $Line
            }

            $LastLine = $Lines.Count

            if ($NewLines -match [regex]::Escape($CompletionMarker)) {
                Write-Output "[OK] Windows Update task completed."
                break
            }
        }
    }

    Start-Sleep -Seconds 2
}

if (Test-Path $LogFile) {
    Remove-Item $LogFile
}

Write-Output "============================================================"
Write-Output "[INFO] Task name : $TaskName"
Write-Output "[INFO] Script    : $ScriptPath"
Write-Output "[INFO] Log file  : $LogFile"
Write-Output "[INFO] Finished  : $(Get-Date)"
Write-Output "============================================================"
