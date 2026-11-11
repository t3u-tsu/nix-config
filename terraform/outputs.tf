output "instance_id" {
  description = "Numeric instance ID of the primary Tokyo failover node."
  value       = google_compute_instance.failover.instance_id
}

output "instance_self_link" {
  description = "Self link URI of the primary Tokyo failover node."
  value       = google_compute_instance.failover.self_link
}

output "instance_zone" {
  description = "GCP zone of the primary Tokyo failover node."
  value       = google_compute_instance.failover.zone
}

output "instance_current_status" {
  description = "Current running status of the primary Tokyo failover node (RUNNING / TERMINATED)."
  value       = google_compute_instance.failover.current_status
}

output "instance_public_ip" {
  description = "Ephemeral public IPv4 of the primary Tokyo failover node (null if stopped)."
  value       = try(google_compute_instance.failover.network_interface[0].access_config[0].nat_ip, null)
}

output "boot_disk_id" {
  description = "ID of the 10GB pd-standard boot disk."
  value       = google_compute_disk.boot.id
}

# --- US Watcher Outputs (Conditional) ---

output "us_watcher_instance_id" {
  description = "Numeric instance ID of the US watcher node, if enabled."
  value       = var.enable_us_watcher ? google_compute_instance.us_watcher[0].instance_id : null
}

output "us_watcher_zone" {
  description = "Zone of the US watcher node, if enabled."
  value       = var.enable_us_watcher ? google_compute_instance.us_watcher[0].zone : null
}

output "us_watcher_current_status" {
  description = "Current running status of the US watcher node, if enabled."
  value       = var.enable_us_watcher ? google_compute_instance.us_watcher[0].current_status : null
}

output "us_watcher_public_ip" {
  description = "Public IPv4 of the US watcher node, if assigned."
  value       = var.enable_us_watcher && var.assign_us_watcher_public_ipv4 ? try(google_compute_instance.us_watcher[0].network_interface[0].access_config[0].nat_ip, null) : null
}
