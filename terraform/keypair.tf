resource "conohavps_keypair" "t3u" {
  name       = "t3u"
  public_key = var.ssh_public_key
}
