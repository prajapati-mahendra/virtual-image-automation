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
exclude_from_latest = true

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
########################

########################
### Image Gallery for vdi
########################
# subscription_id                     = "d658f392-d9ce-4934-b4b8-2f4de1e8b45a"
# virtual_network_resource_group_name = "tcs-prod-int-vdi-core-cus-rg"
# virtual_network_name                = "tcs-prod-int-vdi-core-cus-vnet"
# virtual_network_subnet_name         = "tcs-prod-int-vdi-core-cus-image-build-subnet"
# image_resource_group                = "tcs-prod-int-vdi-core-cus-rg"
# image_gallery_name                  = "tcs_prod_int_vdi_core_cus_compute_gallery"
# image_definition                    = "tcs-prod-int-vdi-core-cus-base-edp-win11-25h2"
# image_offer                         = "tcs-prod-int-vdi-core-cus-base-edp-win11-25h2"
# image_publisher                     = "tas"
# image_sku                           = "tcs-prod-int-vdi-core-cus-base-edp-win11-25h2"
# image_version                       = "0.0.10"
# destination_image_version           = "1.0.0"
# location                            = "centralus"
# vm_size                             = "Standard_D4as_v5"
# license_type                        = "Windows_Client" # For server: "Windows_Server"
########################
