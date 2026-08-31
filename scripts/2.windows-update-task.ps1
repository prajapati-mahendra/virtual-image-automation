$ErrorActionPreference = "Stop"

$LogFile = "C:\Windows\Temp\windows-update-task.log"

# Make sure the directory exists
$LogDirectory = Split-Path $LogFile -Parent

if (-not (Test-Path $LogDirectory))
{
    New-Item -Path $LogDirectory -ItemType Directory -Force | Out-Null
}

Start-Transcript -Path $LogFile -Append

try
{

    Write-Output "============================================================"
    Write-Output " Packer Windows Update"
    Write-Output "============================================================"
    Write-Output "[INFO] Running as : $( whoami )"
    Write-Output "[INFO] Started    : $( Get-Date )"

    # --------------------------------------------------------
    # Verify SYSTEM
    # --------------------------------------------------------

    Write-Output ""
    Write-Output "[VERIFY] Checking execution identity..."
    $CurrentIdentity = [Security.Principal.WindowsIdentity]::GetCurrent()
    Write-Output "[VERIFY] User: $( $CurrentIdentity.Name )"
    $Principal = New-Object Security.Principal.WindowsPrincipal($CurrentIdentity)
    $IsAdministrator = $Principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    Write-Output "[VERIFY] Administrator: $IsAdministrator"

    # --------------------------------------------------------
    # Execution Policy
    # --------------------------------------------------------

    Write-Output ""
    Write-Output "[Policy] Setting up bypass policy..."
    Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process -Force
    Write-Output "[OK] Execution policy configured."

    # --------------------------------------------------------
    # NuGet & PSWindowsUpdate
    # --------------------------------------------------------

    Write-Output ""
    Write-Output "[Package Provider] Verifying NuGet and WindowsUpdate module..."
    if (-not (Get-Module -ListAvailable -Name PSWindowsUpdate))
    {

        Write-Output "[Install Module] Installing PSWindowsUpdate..."

        Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force

        # --------------------------------------------------------
        # PSRespository
        # --------------------------------------------------------
        Write-Output "[Respository] Registering Repository..."
        Register-PSRepository -Default -ErrorAction SilentlyContinue

        Install-Module -Name PSWindowsUpdate -Force -Scope AllUsers -ErrorAction Stop

    }
    else
    {
        Write-Output "[OK] PSWindowsUpdate already installed."
    }

    Import-Module PSWindowsUpdate
    # --------------------------------------------------------
    # Windows Updates
    # --------------------------------------------------------

    Write-Output ""
    Write-Output "[Update] Fetching and Installing Updating Windows..."
    $Updates = Get-WindowsUpdate
    Write-Output ""
    if ($null -eq $Updates -or $Updates.Count -eq 0)
    {
        Write-Output "[Update] No Windows update available."
    }
    else
    {
        Write-Output "[Update] $( $Updates.Count ) update(s) available..."
        $Updates | Format-Table

        Write-Output ""
        Write-Output "[Update] Installing Windows Updates..."
        Get-WindowsUpdate -AcceptAll -Install -IgnoreReboot -Verbose *>&1
    }
    Write-Output ""
    Write-Output "============================================================"
    Write-Output " Windows Update task completed"
    Write-Output " Finished: $( Get-Date )"
    Write-Output "============================================================"
}
catch
{

    Write-Output ""
    Write-Output "============================================================"
    Write-Output " ERROR"
    Write-Output "============================================================"

    Write-Output "[ERROR] Message: $( $_.Exception.Message )"
    Write-Output "[ERROR] Type   : $( $_.Exception.GetType().FullName )"
    Write-Output "[ERROR] Stack  :"
    Write-Output $_.ScriptStackTrace

    throw
}
finally
{

    Write-Output ""
    Write-Output "[INFO] Stopping PowerShell transcript..."

    Stop-Transcript
}