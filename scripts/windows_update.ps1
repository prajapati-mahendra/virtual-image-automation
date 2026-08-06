Write-Output '>>> Installing NuGet'
New-ItemProperty -Path 'HKLM:\SOFTWARE\Packer\' -Name 'taskMessage' -Value 'Installing NuGet' -PropertyType 'String' -Force
Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force

Write-Output '>>> Installing Windows Update Module'
New-ItemProperty -Path 'HKLM:\SOFTWARE\Packer\' -Name 'taskMessage' -Value 'Installing psWindowsUpdate' -PropertyType 'String' -Force
Install-Module pswindowsupdate -Force

Write-Output '>>> Installing windows update'
New-ItemProperty -Path 'HKLM:\SOFTWARE\Packer\' -Name 'taskMessage' -Value 'Installing Windows Updates' -PropertyType 'String' -Force
Get-WindowsUpdate -Install -AcceptAll -IgnoreReboot -Verbose 4

Write-Output '>>> Updating Registry'
New-ItemProperty -Path 'HKLM:\SOFTWARE\Packer\' -Name 'taskMessage' -Value 'Complete' -PropertyType 'String' -Force
New-ItemProperty -Path 'HKLM:\SOFTWARE\Packer\' -Name 'taskCompleted' -Value '1' -PropertyType 'String' -Force