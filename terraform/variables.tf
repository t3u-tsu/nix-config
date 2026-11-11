variable "gcp_project_id" {
  type        = string
  description = "Google Cloud Platform Project ID."
}

variable "gcp_region" {
  type        = string
  default     = "asia-northeast1"
  description = "Default GCP region for failover infrastructure (Tokyo)."
}

variable "gcp_zone" {
  type        = string
  default     = "asia-northeast1-b"
  description = "Default GCP zone for the primary Tokyo failover instance."
}

variable "instance_name" {
  type        = string
  default     = "torii-chan-gcp"
  description = "Instance name for the primary Tokyo failover node."
}

variable "ssh_public_key" {
  type        = string
  default     = null
  description = "Optional SSH public key for bootstrap and emergency access."
}

variable "boot_disk_size_gb" {
  type        = number
  default     = 10
  description = "Boot disk size in GB (must be pd-standard for $0.48/mo cost optimization)."
}

variable "boot_image" {
  type        = string
  default     = "debian-cloud/debian-12"
  description = "Initial boot image used for provisioning before NixOS kexec / nixos-anywhere."
}

variable "allowed_ssh_cidrs" {
  type        = list(string)
  default     = ["0.0.0.0/0"]
  description = "Allowed CIDR ranges for inbound SSH (22/tcp)."
}

# --- Optional US Always Free Watcher Instance ---

variable "enable_us_watcher" {
  type        = bool
  default     = false
  description = "Whether to provision the secondary 24/7 Always Free watcher instance in a US region."
}

variable "us_watcher_name" {
  type        = string
  default     = "torii-chan-gcp-us"
  description = "Instance name for the US Always Free watcher node."
}

variable "us_watcher_zone" {
  type        = string
  default     = "us-west1-b"
  description = "GCP zone for the US watcher instance (must be in us-west1, us-central1, or us-east1 for Always Free)."
}

variable "us_boot_disk_size_gb" {
  type        = number
  default     = 15
  description = "Boot disk size in GB for the US watcher instance (pd-standard, max 30GB total across free tier)."
}

variable "assign_us_watcher_public_ipv4" {
  type        = bool
  default     = false
  description = "Assign external IPv4 to US watcher. NOTE: GCP charges $0.005/h ($3.65/mo) for running external IPv4 since Feb 2024. Leave false and use IPv6 or Cloudflare Tunnel to maintain $0.00 cost."
}
