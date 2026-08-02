variable "instance_name" {
  description = "ConoHa VPS インスタンス名（metadata.instance_name_tag）"
  type        = string
  default     = "torii-chan"
}

variable "flavor_id" {
  description = "ConoHa VPS Flavor ID（512MB プラン: g2l-t-c1m512 = 1 vCPU / 512MB）"
  type        = string
  default     = "3f8244e7-c7a2-4c60-84b9-cd76dd98a177"
}

variable "boot_image_id" {
  description = "ブートボリューム作成用の ConoHa 標準イメージ ID。NixOS を rescue ISO で上書きするまでの仮 OS（vmi-debian-12.05-amd64）"
  type        = string
  default     = "859b738c-b817-4b93-9e17-694cd6c37eb1"
}

variable "boot_volume_size" {
  description = "ブートボリュームサイズ（GB）。ConoHa の許容値: 30/100/200/500/1000/5000/10000"
  type        = number
  default     = 30
}

variable "admin_password" {
  description = "インスタンス管理者パスワード（9-70 文字、英大・英小・数字・記号を含む）。TF_VAR_admin_password または *.tfvars で必ず指定する"
  type        = string
  sensitive   = true
}

variable "ssh_public_key" {
  description = "SSH 公開鍵（キーペア t3u に登録。vps.nix の authorizedKeys と同じ鍵を使う）"
  type        = string
}
