# オペレーター用 SSH キーペア。
# vps.nix の my.user.authorizedKeys と同じ公開鍵を使う（全ホスト共通の t3u 鍵）。
resource "conohavps_keypair" "t3u" {
  name       = "t3u"
  public_key = var.ssh_public_key
}
