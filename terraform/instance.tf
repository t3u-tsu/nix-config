# Boot volume (30GB).
# Note: NixOS is later installed over the disk via a rescue ISO (scripts/nixos-iso.sh),
#       so here we temporarily deploy the ConoHa stock OS (Debian 12) to establish an SSH path.
resource "conohavps_volume" "boot" {
  name        = "${var.instance_name}-boot"
  description = "torii-chan VPS boot volume (OS replaced with NixOS via rescue ISO)"
  size        = var.boot_volume_size
  image_ref   = var.boot_image_id
  volume_type = "c3j1-ds02-boot"
}

# VPS instance (512MB plan: g2l-t-c1m512).
# References the keypair and security group created in this same tf file.
resource "conohavps_instance" "torii_chan" {
  instance_name_tag = var.instance_name
  admin_pass        = var.admin_password
  flavor_id         = var.flavor_id
  block_device = [
    {
      uuid = conohavps_volume.boot.id
    }
  ]
  security_group = [
    {
      name = conohavps_securitygroup.torii_chan.name
    },
  ]
  key_name    = conohavps_keypair.t3u.name
  power_state = "ACTIVE"
}
