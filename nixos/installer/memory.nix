# nixos/installer/memory.nix - 512MB RAM 向けの低メモリチューニング
#
# 背景:
#   ライブ環境（ISO 起動後）の /nix/store は「squashfs（読み取り専用）+ tmpfs
#   オーバーレイ（書き込み用）」で構成される。tmpfs は RAM 上にあるため、
#   nixos-install 時にキャッシュ（cache.nixos.org）から不足分のストアパスを
#   ダウンロードして展開すると RAM を消費する。512MB では OOM しやすいため、
#   以下の対策を組み込む:
#
#   1. zram（圧縮スワップ）でメモリ不足を吸収
#   2. カーネルのオーバーコミット設定（installation-device.nix が既に
#      vm.overcommit_memory = 1 を設定済み）
#   3. スワップを積極利用（vm.swappiness を高めに）
#
#   さらに、nixos-install のクロージャコピーを軽くする手段として、ターゲット
#   システムのクロージャを ISO のストアに含める方法もある（isoImage.storeContents
#   に system.build.toplevel を追加）。詳細は docs/conoha-vps-installer-iso.md 参照。
{
  lib,
  ...
}:

{
  config = {
    # zram: メモリの半分（=約 256MB 相当）を圧縮スワップとして確保
    zramSwap = {
      enable = true;
      algorithm = "lz4"; # 1 vCPU のため高速な圧縮アルゴリズムを選択（デフォルトは zstd）
      memoryPercent = 50;
      priority = 100; # ディスクスワップより優先して利用
    };

    boot.kernel.sysctl = {
      # 余剰 RAM を zram に積極的に退避させて OOM を防ぐ
      "vm.swappiness" = 100;
    };

    # ヘッドレス（VNC / シリアル）コンソール向けカーネルパラメータ。
    # console=ttyS0 はシリアルコンソールの有効化、nomodeset は VNC での
    # 文字表示を確実にするための指定。
    boot.kernelParams = [
      "console=tty0"
      "console=ttyS0,115200n8"
      "nomodeset"
    ];
  };
}
