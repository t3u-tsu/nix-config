# hosts/torii-chan/sd-installer.nix - Orange Pi Zero3 用 SD インストーライメージ
#
# stage: installer の SD カードイメージ（本番サービスなし・一時パスワードで SSH 可）。
# 旧 sd-image-installer.nix を installer-common.nix（VPS インストーラと共用）方式に
# 再設計したもの。本番 SD（torii-chan-sd）や HDD 本番（torii-chan-hdd）への
# プロビジョニング専用であり、WireGuard / DDNS / NAT は実行しない。
#
# ビルド（一時パスワード自動発行）:
#   ./hosts/torii-chan/build-sd-image.sh
{
  pkgs,
  modulesPath,
  lib,
  ...
}:

{
  imports = [
    (modulesPath + "/installer/sd-card/sd-image-aarch64.nix")
    ./installer-common.nix
  ];

  # Disable SD image compression for faster build times and immediate flashing.
  sdImage.compressImage = false;

  # Silence ZFS evaluation warning for the installer image
  boot.zfs.forceImportRoot = false;

  # Write U-Boot to the image for Orange Pi Zero3
  # Assumes ubootOrangePiZero3 is provided via Overlays in flake.nix
  sdImage.postBuildCommands = ''
    echo "Writing U-Boot to image..."
    dd if=${pkgs.ubootOrangePiZero3}/u-boot-sunxi-with-spl.bin of=$img bs=1024 seek=8 conv=notrunc
  '';

  # --- SBC インストーラ: LAN 内プロビジョニング専用 ---
  # 一時パスワード + パスワード認証可（"緩め"）で、焼いた直後に SSH から
  # そのまま作業できる。ネットワークは sbc.nix の静的 IP（192.168.0.128）。
  # ファイアウォールは 22 のみ開放（本番の wg0 制限とは無関係の素の LAN 状態）。
  my.installer = {
    enable = true;
    # LAN 内限定なので一時パスワードでのログインを許可（VPS インストーラは鍵のみ）
    allowPasswordAuthentication = true;
    firewallOpenPorts = [ 22 ];
  };
}
