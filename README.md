# Azure Virtual Machine Image Automation with Hashicorp Packer

## Pre-requisites
- Azure CLI
- Packer CLI

## Variable File
Please ask the owner foe the file `windows.auto.pkrvars.hcl`

## Build Steps
```shell
packer validate .
packer build .
```