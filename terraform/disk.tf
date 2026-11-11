# Primary failover boot disk in Tokyo (pd-standard 10GB = $0.48/month = $5.76/year)
resource "google_compute_disk" "boot" {
  name  = "${var.instance_name}-boot"
  type  = "pd-standard"
  size  = var.boot_disk_size_gb
  zone  = var.gcp_zone
  image = var.boot_image

  labels = {
    role        = "failover-gateway"
    environment = "production"
    managed_by  = "opentofu"
  }

  lifecycle {
    # Prevent recreation when Debian image pointer updates after NixOS is installed
    ignore_changes = [
      image,
    ]
  }
}

# Optional US Always Free watcher boot disk (pd-standard 15GB <= 30GB Always Free = $0.00/month)
resource "google_compute_disk" "us_boot" {
  count = var.enable_us_watcher ? 1 : 0
  name  = "${var.us_watcher_name}-boot"
  type  = "pd-standard"
  size  = var.us_boot_disk_size_gb
  zone  = var.us_watcher_zone
  image = var.boot_image

  labels = {
    role        = "watcher-gateway"
    environment = "production"
    managed_by  = "opentofu"
  }

  lifecycle {
    ignore_changes = [
      image,
    ]
  }
}
