# ─────────────────────────────────────────────────────────────────────────────
# Variables
# These are supplied via .pkrvars.hcl or environment variables at runtime.
# ─────────────────────────────────────────────────────────────────────────────
variable "subscription_id" {
  type = string
  default = env("ARM_SUBSCRIPTION_ID")
}

variable "image_resource_group" {
  type = string
  default = env("ARM_RESOURCE_GROUP")
}

variable "image_gallery_name" {
  type = string
}

variable "image_definition" {
  type = string
}

variable "image_version" {
  type = string
}

variable "destination_image_version" {
  type = string
}

variable "image_offer" {
  type = string
}

variable "image_publisher" {
  type = string
}

variable "image_sku" {
  type = string
}

variable "location" {
  type = string
}

variable "vm_size" {
  type = string
}

variable "exclude_from_latest" {
  type    = bool
  default = true
}

variable "winrm_password" {
  type = string
}

variable "license_type" {
  type = string
}

variable "virtual_network_name" {
  type = string
}

variable "virtual_network_subnet_name" {
  type = string
}

variable "virtual_network_resource_group_name" {
  type = string
}

variable "encryption_at_host" {
  type    = bool
  default = false
}

variable tags {
  type = map(string)
}
