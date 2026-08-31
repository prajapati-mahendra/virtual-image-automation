# VM Automation using Azure VM and Packer

## Pre-requisites
- `az, jq, fzf` cli. If not found, please install the using `brew`
- `Windows App` from Self Service
- Download HasiCorp Packer 1.16.0 using [link](https://releases.hashicorp.com/packer/1.16.0/packer_1.16.0_windows_amd64.zip)
- Download HashiCorp Packer Azure plugin v2.6.3 using this [link](https://releases.hashicorp.com/packer-plugin-azure/2.6.3/)

## Automation Steps

### 1. Create a Windows VM with following configurations:
##### General:
- Create a new temporary resource group. Name is can be anything.
- Set Username: `azuser` and password as per azure policy.
- License Type: Windows Client

##### Disk:
- Must check `Encryption at host`.

##### Networking:
- Virtual Network: `tcs-prod-ext-rad-cll-core-cus-vnet`
- Subnet: `tcs-prod-ext-rad-cll-core-cus-image-build-subnet`
- Public IP: `None`
- NIC Group: `Advance`
- Configure NIC Group: `tcs-prod-ext-rad-cll-core-cus-image-build-subnet`

### 2. Connect to VM
- Connect the Host system to right Gateway in order to connect VM.
- Once VM is created from [Step 1](#1-create-a-windows-vm-with-following-configurations), Please use this [script](./scripts/bastian.sh) to connect to VM
- Run the following command to source bastian script:
  ```shell
  source doc/scripts/bastian.sh
  bastionConnection
  ```
  Here, tunnel port is `13389` default port at host. 3389 is the standard port at VM
- Above function will ask to select the right subscription and VM to create tunnel. By-default, it will open the tunnel with `13389:3389` mapping; but it can be overridden by passing mapping as param in format `<port at Host>:<RDP Port of VM>`. E.g
  ```shell
  source doc/scripts/bastian.sh
  bastionConnection "23389:3389"
  ```
  Here, `23389` is overridden port. 3389 is the standard port at VM.
- Open the `Windows App` and add a PC with following details:
  - PC name: `localhost:<port at host>`
  - Add Credentials which was given in [Step 1.2](#1-create-a-windows-vm-with-following-configurations)
  - Click Add
  - Allow the certificate to link.

### 3. Set up the Hashicorp Packer and Azure plugin
- Drag and Drop both zip file downloaded from [Pre-requisites](#pre-requisites)
- Unzip both of them and add packer CLI to system path.
- To add the plugin, run the following command in the terminal/powershell
  ```powershell
  packer plugins install --path <packer-plugin-exe-location> github.com/hashicorp/azurerm
  ```

### 4. Create variable files
Create a file at root of the cloned repository. File name must be `windows.auto.pkrvars.hcl` with following content
```hcl
########################
# Tags
########################
tags = {
  team               = "TAS"
  stage              = "dev"
  Cell               = "tcs.prod.ext.rad-cll.core"
  CostCenter         = "RnD"
  onboardingStrategy = "IAC"
}
########################
exclude_from_latest = false

########################
### Image Gallery for CLL
########################
subscription_id           = "bde07918-0447-48ae-8b33-7dac09045dac"
image_resource_group      = "tcs-prod-ext-rad-cll-core-rg"
virtual_network_resource_group_name = "tcs-prod-ext-rad-cll-core-cus-rg"
virtual_network_name                = "tcs-prod-ext-rad-cll-core-cus-vnet"
virtual_network_subnet_name         = "tcs-prod-ext-rad-cll-core-cus-image-build-subnet"
image_gallery_name        = "tcs_prod_ext_rad_cll_core_compute_gallery"
image_definition          = "tcs-prod-ext-rad-cll-core-base-edp-win11-25h2"
image_offer               = "tcs-prod-ext-rad-cll-core-base-edp-win11-25h2"
image_publisher           = "tas"
image_sku                 = "tcs-prod-ext-rad-cll-core-base-edp-win11-25h2"
image_version             = "0.0.10"
destination_image_version = "1.0.0"
location                  = "centralus"
vm_size                   = "Standard_D4as_v5"
license_type              = "Windows_Client" # For server: "Windows_Server"
```
**_Note: Please update the image_version. Use the version which is latest._**

### 5. Start the Packer
- Source and run the build PowerShell function from script
```powershell
mkdir log
. .\build.ps1
packer-build .
```
This will create the schedule function and run the packer provisioner one by one and perform the Windows update in 3 phase.

_💻 Happy Hacking_