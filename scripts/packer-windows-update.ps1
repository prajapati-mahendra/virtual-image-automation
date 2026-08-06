[string]$taskName = 'windowsUpdate'
[string]$updateScriptPath = 'c:\temp\build\scripts\windowsUpdate.ps1'

Write-Output "============================================"
Write-Output "Starting Windows Update provisioning script"
Write-Output "============================================"
Write-Output "Task Name: $taskName"
Write-Output "Update Script Path: $updateScriptPath"

Write-Output "--> Creating registry key 'HKLM:\SOFTWARE\Packer\'..."
New-Item -Path 'HKLM:\SOFTWARE\Packer\'
New-ItemProperty -Path 'HKLM:\SOFTWARE\Packer\' -Name 'taskCompleted' -Value '0' -PropertyType 'String' -Force
Write-Output "--> Registry key created and taskCompleted set to 0."

Write-Output "--> Creating scheduled task action..."
$action = New-ScheduledTaskAction -Execute 'Powershell.exe' -Argument "-file $updateScriptPath -ExecutionPolicy Bypass"
Write-Output "--> Registering scheduled task '$taskName'..."
Register-ScheduledTask -Action $action -User 'NT AUTHORITY\SYSTEM' -TaskName 'windowsUpdate' -Description "created by packer"
Write-Output "--> Scheduled task '$taskName' registered successfully."

Write-Output "--> Starting scheduled task '$taskName'..."
Start-ScheduledTask -TaskName $taskName
Write-Output "--> Scheduled task '$taskName' started. Monitoring for completion..."

$stopWatch = [System.Diagnostics.Stopwatch]::StartNew()

while($true) {
    $taskStatus = Get-ItemProperty 'HKLM:\SOFTWARE\Packer\' | Select-Object taskCompleted
    $taskMessageItem = Get-ItemProperty 'HKLM:\SOFTWARE\Packer\' | Select-Object taskMessage
    $taskMessageValue =  $taskMessageItem.taskMessage

    if ($taskStatus.taskCompleted -ne '1') {
        $elapsed = '{0:D2}:{1:D2}:{2:D2}' -f $stopWatch.Elapsed.Hours, $stopWatch.Elapsed.Minutes, $stopWatch.Elapsed.Seconds
        Write-Output "⏳[$elapsed] Waiting for completion of task '$taskName' | Status: In Progress | Message: $taskMessageValue"
        Start-Sleep -s 15
    }
    else {
        $elapsed = '{0:D2}:{1:D2}:{2:D2}' -f $stopWatch.Elapsed.Hours, $stopWatch.Elapsed.Minutes, $stopWatch.Elapsed.Seconds
        Write-Output "============================================"
        Write-Output "[$elapsed] Task '$taskName' COMPLETED successfully!"
        Write-Output "Final Message: $taskMessageValue"
        Write-Output "============================================"
        break
    }
}