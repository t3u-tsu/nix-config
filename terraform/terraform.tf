terraform {
  required_version = ">= 1.0"

  required_providers {
    conohavps = {
      # Fully-qualified source so OpenTofu also resolves it from the Terraform
      # registry (the provider is not published on registry.opentofu.org).
      source = "registry.terraform.io/gmo-internet/conohavps"
    }
  }
}
