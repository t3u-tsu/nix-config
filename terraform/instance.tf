# Primary low-latency failover node in Tokyo (asia-northeast1)
# Standby state: TERMINATED (stopped). Boot disk retained ($0.48/mo).
# On SBC outage: started on-demand via gcloud/API/MCP. Ephemeral IP auto-released upon stop ($0.00 idle cost).
resource "google_compute_instance" "failover" {
  name         = var.instance_name
  machine_type = "e2-micro"
  zone         = var.gcp_zone

  tags = ["torii-chan-gateway", "failover-node"]

  boot_disk {
    source      = google_compute_disk.boot.self_link
    auto_delete = false
  }

  network_interface {
    network = "default"
    # Ephemeral external IPv4. Released when instance stops, incurring $0.00 cost while idle.
    access_config {
      // ephemeral public IP
    }
  }

  metadata = {
    enable-oslogin = "FALSE"
    ssh-keys       = var.ssh_public_key != null && var.ssh_public_key != "" ? "root:${var.ssh_public_key}" : null
  }

  # Enable IP forwarding for gateway NAT and DNAT port forwarding (TCP 25565 -> Nebula LAN)
  can_ip_forward = true

  # Allow stopping instance when updates require it instead of forcing destroy/recreate
  allow_stopping_for_update = true

  scheduling {
    preemptible         = false
    automatic_restart   = true
    on_host_maintenance = "MIGRATE"
  }

  labels = {
    role        = "failover-gateway"
    environment = "production"
    managed_by  = "opentofu"
  }

  lifecycle {
    # Instance is dynamically started and stopped during failover events.
    # Prevent OpenTofu from overriding runtime power state (RUNNING/TERMINATED).
    ignore_changes = [
      desired_status,
    ]
  }
}

# Optional US Always Free 24/7 Watcher node (us-west1)
# Compute: e2-micro (Always Free 744h/mo) + pd-standard (Always Free <=30GB)
resource "google_compute_instance" "us_watcher" {
  count        = var.enable_us_watcher ? 1 : 0
  name         = var.us_watcher_name
  machine_type = "e2-micro"
  zone         = var.us_watcher_zone

  tags = ["torii-chan-gateway", "watcher-node"]

  boot_disk {
    source      = google_compute_disk.us_boot[0].self_link
    auto_delete = false
  }

  network_interface {
    network = "default"

    # Only assign external IPv4 if explicitly enabled to prevent post-2024 $0.005/h IPv4 charges.
    dynamic "access_config" {
      for_each = var.assign_us_watcher_public_ipv4 ? [1] : []
      content {}
    }
  }

  metadata = {
    enable-oslogin = "FALSE"
    ssh-keys       = var.ssh_public_key != null && var.ssh_public_key != "" ? "root:${var.ssh_public_key}" : null
  }

  can_ip_forward            = false
  allow_stopping_for_update = true

  scheduling {
    preemptible         = false
    automatic_restart   = true
    on_host_maintenance = "MIGRATE"
  }

  labels = {
    role        = "watcher-gateway"
    environment = "production"
    managed_by  = "opentofu"
  }
}
