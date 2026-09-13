terraform {
  required_version = ">= 1.0"

  required_providers {
    conohavps = {
      source  = "registry.terraform.io/gmo-internet/conohavps"
      version = "~> 0.1.0"
    }
  }
}
