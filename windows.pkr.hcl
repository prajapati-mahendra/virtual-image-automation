# ─────────────────────────────────────────────────────────────────────────────
# Source Block
# Defines the Azure VM configuration used to build the image.
# Packer spins up a temporary VM from this config, runs provisioners, then
# captures the result into the Compute Gallery.
# ─────────────────────────────────────────────────────────────────────────────
source "azure-arm" "packer-test" {

  # Authentication: uses the locally authenticated Azure CLI session
  use_azure_cli_auth = true
  subscription_id = var.subscription_id

  # Override networking configuration to avoid creation of temporary resources
  virtual_network_name                = var.virtual_network_name
  virtual_network_subnet_name         = var.virtual_network_subnet_name
  virtual_network_resource_group_name = var.virtual_network_resource_group_name


  # ── Destination ──────────────────────────────────────────────────────────
  # Where the final generalized image will be published after build completes.
  shared_image_gallery_destination {
    subscription   = var.subscription_id
    resource_group = var.image_resource_group
    gallery_name   = var.image_gallery_name
    image_name     = var.image_definition
    image_version  = var.destination_image_version
  }
  shared_gallery_image_version_exclude_from_latest = var.exclude_from_latest

  # ── Build VM Properties ──────────────────────────────────────────────────
  # Packer creates a temporary resource group and VM for the build process.
  # Use build_resource_group_name to override the auto-generated temp RG.
  # build_resource_group_name = var.virtual_network_resource_group_name
  os_type      = "Windows"
  license_type = var.license_type

  # ── Trusted Launch ──────────────────────────────────────────────────────
  # Required because the gallery image definition uses TrustedLaunch security type.
  # The build VM must match, otherwise Azure rejects the deployment.
  security_type       = "TrustedLaunch"
  secure_boot_enabled = true
  vtpm_enabled        = true

  # ── Source Image ─────────────────────────────────────────────────────────
  # Pull the base image from our own Azure Compute Gallery.
  # This must have at least one existing version published in the gallery.
  shared_image_gallery {
    subscription   = var.subscription_id
    resource_group = var.image_resource_group
    gallery_name   = var.image_gallery_name
    image_name     = var.image_definition
    image_version  = var.image_version
  }

  # ── WinRM Communication ─────────────────────────────────────────────────
  # Packer connects to the VM via WinRM over HTTPS to run provisioners.
  communicator   = "winrm"
  winrm_use_ssl  = true
  winrm_insecure = true
  winrm_username = "packer"
  winrm_password = var.winrm_password
  winrm_timeout  = "15m"
  keep_os_disk = true

  # ── VM Size & Location ──────────────────────────────────────────────────
  vm_size            = var.vm_size
  location           = var.location
  encryption_at_host = var.encryption_at_host

  # ── Tags ────────────────────────────────────────────────────────────────
  # Applied to all temporary resources created during the build.
  azure_tags = var.tags

}

build {
  sources = ["source.azure-arm.packer-test"]

  # # 1. Clear any pending reboots left by Azure VM initialization
  # provisioner "windows-restart" {
  #   restart_check_command = "powershell -command \"& {Write-Output 'rebooted'}\""
  #   restart_timeout       = "15m"
  # }

  # # 2. Copy Windows update script
  # provisioner "file" {
  #   source      = "scripts/windows_update.ps1"
  #   destination = "c:\\temp\\build\\scripts\\windows_update.ps1"
  # }

  # provisioner "powershell" {
  #   script = "scripts/ws-update.ps1"
  # }

  # 2. Run updates with essential filters and batch limits
  provisioner "windows-update" {
  }

  # # 3. Final reboot after updates are installed
  # provisioner "windows-restart" {
  #   restart_check_command = "powershell -command \"& {Write-Output 'rebooted'}\""
  #   restart_timeout       = "15m"
  # }

  provisioner "powershell" {
    inline = [
      "Write-host '=== Azure image build completed successfully ==='",
      "Write-host '=== Generalising the image ... ==='",
      "& $env:SystemRoot\\System32\\Sysprep\\Sysprep.exe /generalize /oobe /quit",
      "while($true) { $imageState = Get-ItemProperty HKLM:\\SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Setup\\State | Select ImageState; if($imageState.ImageState -ne 'IMAGE_STATE_GENERALIZE_RESEAL_TO_OOBE') { Write-Output $imageState.ImageState; Start-Sleep -s 10  } else { break } }"
    ]
  }
}
