# SSH keypair for the operator.
# Use the same public key as vps.nix's my.user.authorizedKeys (t3u key shared across all hosts).
resource "conohavps_keypair" "t3u" {
  name       = "t3u"
  public_key = var.ssh_public_key
}
