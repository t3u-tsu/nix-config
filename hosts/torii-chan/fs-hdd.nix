{ config, lib, pkgs, ... }:

{
  # HDD運用用のファイルシステム設定
  # 前提:
  # 1. USB接続のHDD/SSDが接続されていること。
  # 2. そのHDDにext4パーティションが作成され、ラベル "NIXOS_HDD" が付与されていること。
  # 3. SDカードの中身（特に /nix と /boot）がHDDにコピーされていること。

  fileSystems."/" = {
    device = "/dev/disk/by-label/NIXOS_HDD";
    fsType = "ext4";
    # USBストレージの認識待ちなどでブートに失敗しないよう、重要フラグを立てる
    neededForBoot = true;
  };

  # SDカードの元のルートパーティションを /boot としてマウントする
  # これにより、カーネルの更新などがSDカード側に書き込まれ、U-Bootがそれを読み込める状態を維持する
  fileSystems."/boot" = {
    device = "/dev/disk/by-label/NIXOS_SD";
    fsType = "ext4";
  };
}
