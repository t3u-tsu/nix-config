# Inbound SSH bootstrap and administrative access
resource "google_compute_firewall" "allow_ssh" {
  name        = "torii-chan-allow-ssh"
  network     = "default"
  priority    = 1000
  direction   = "INGRESS"
  description = "Allow inbound SSH access for bootstrap and administration"

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = var.allowed_ssh_cidrs
  target_tags   = ["torii-chan-gateway"]
}

# Inbound Nebula Mesh VPN lighthouse and encrypted overlay relay traffic
resource "google_compute_firewall" "allow_nebula" {
  name        = "torii-chan-allow-nebula"
  network     = "default"
  priority    = 1000
  direction   = "INGRESS"
  description = "Allow Nebula mesh lighthouse and relay UDP packets"

  allow {
    protocol = "udp"
    ports    = ["4242"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["torii-chan-gateway"]
}

# Inbound Minecraft server proxy traffic (DNAT forwarded to LAN host)
resource "google_compute_firewall" "allow_minecraft" {
  name        = "torii-chan-allow-minecraft"
  network     = "default"
  priority    = 1000
  direction   = "INGRESS"
  description = "Allow inbound Minecraft server traffic forwarded to internal LAN host"

  allow {
    protocol = "tcp"
    ports    = ["25565"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["torii-chan-gateway"]
}

# Inbound ICMP for latency probing, diagnostic ping, and uptime monitoring
resource "google_compute_firewall" "allow_icmp" {
  name        = "torii-chan-allow-icmp"
  network     = "default"
  priority    = 1000
  direction   = "INGRESS"
  description = "Allow inbound ICMP for latency probing and external health checks"

  allow {
    protocol = "icmp"
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["torii-chan-gateway"]
}
