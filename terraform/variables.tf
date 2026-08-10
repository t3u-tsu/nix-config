variable "instance_name" {
  description = "ConoHa VPS instance name (metadata.instance_name_tag)"
  type        = string
  default     = "torii-chan"
}

variable "flavor_id" {
  description = "ConoHa VPS Flavor ID (512MB plan: g2l-t-c1m512 = 1 vCPU / 512MB)"
  type        = string
  default     = "3f8244e7-c7a2-4c60-84b9-cd76dd98a177"
}

variable "boot_image_id" {
  description = "ConoHa stock image ID for creating the boot volume. Temporary OS (vmi-debian-12.05-amd64) until NixOS is installed over it via rescue ISO"
  type        = string
  default     = "859b738c-b817-4b93-9e17-694cd6c37eb1"
}

variable "boot_volume_size" {
  description = "Boot volume size (GB). ConoHa accepted values: 30/100/200/500/1000/5000/10000"
  type        = number
  default     = 30
}

variable "admin_password" {
  description = "Instance admin password (9-70 chars, must include uppercase/lowercase letters, digits and symbols). Must be set via TF_VAR_admin_password or *.tfvars"
  type        = string
  sensitive   = true
}

variable "ssh_public_key" {
  description = "SSH public key (registered in keypair t3u; use the same key as authorizedKeys in vps.nix)"
  type        = string
}
