# ─────────────────────────────────────────────────────────────────────────────
# Packer Plugin Requirements
# Specifies the Azure plugin and minimum version needed to build this image.
# ─────────────────────────────────────────────────────────────────────────────
packer {
  required_plugins {
    azure = {
      source  = "github.com/hashicorp/azure"
      version = ">= 2.3.0"
    }
  }
}