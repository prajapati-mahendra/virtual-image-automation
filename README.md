# Azure Virtual Machine Image Automation with Hashicorp Packer

## Pre-requisites
- Azure CLI
- Packer CLI

## Build and Test Steps
- Launch a VM in azure under targeted subscription
- Run the following command:
  - For Mac/Linux 
    ```shell
    az network bastion tunnel \ 
      --name tcs-prod-int-vdi-core-cus-bastion \
      --resource-group tcs-prod-int-vdi-core-cus-rg \
      --subscription tas-prod-internal-vdi \
      --port 23389 \
      --resource-port 3389 \
      --target-resource-id /subscriptions/d658f392-d9ce-4934-b4b8-2f4de1e8b45a/resourceGroups/packer-automation-rg/providers/Microsoft.Compute/virtualMachines/packer-automation
    ```
  - For PowerShell/Windows Terminal
    ```powershell
    az network bastion tunnel `
      --name tcs-prod-int-vdi-core-cus-bastion `
      --resource-group tcs-prod-int-vdi-core-cus-rg `
      --subscription tas-prod-internal-vdi `
      --port 23389 `
      --resource-port 3389 `
      --target-resource-id /subscriptions/d658f392-d9ce-4934-b4b8-2f4de1e8b45a/resourceGroups/packer-automation-rg/providers/Microsoft.Compute/virtualMachines/packer-automation
    ```
- Connect to Azure VM using RPD Port `23389` with Windows App(can be downloaded from Self Service)
- Login with user Packer and password must be exported before running above steps.
- Download and copy following files:
  - 