# nixos/installer/default.nix - ConoHa VPS (512MB) 用 カスタム NixOS インストーラ ISO 設定
#
# 概要:
#   ConoHa VPS（g2l-t-c1m512 = 1 vCPU / 512MB RAM / 30GB ボリューム）に NixOS を
#   インストールするための「SSH から操作できるインストーラ ISO」を生成するための
#   NixOS モジュール群のエントリポイント。
#
#   標準の NixOS インストーラ ISO は sshd 自体は有効だが、ログインにはコンソールで
#   パスワード設定か authorized_keys の追加が必要で、ConoHa は DHCP を提供しない。
#   そのため VNC コンソールでの手作業（遅い・非対話化が難しい）に依存していた。
#   本モジュールは以下を組み込んで、SSH だけでインストールを完結させる:
#
#     - services.openssh 有効化 + root の authorizedKeys（公開鍵のみ・パスワード認証無効）
#     - 静的 IP 設定（ConoHa は DHCP 無効。IP は conoha.installer.wan で指定）
#     - 512MB 向け低メモリ設定（zram、シリアルコンソール、OOM 対策）
#     - nixos-install 自動化スクリプト install-nixos（同梱・PATH に追加）
#
# ビルド方法:
#   1. リポジトリの flake.nix を変更しない場合（スタンドアロン）:
#        nix build path:./nixos/installer#default -o result-iso
#      （詳細は nixos/installer/README.md と docs/conoha-vps-installer-iso.md を参照）
#   2. リポジトリの flake.nix に統合する場合（別タスクで実施）:
#        modules にこのファイル（またはディレクトリ）を追加し、
#        config.system.build.images.iso-installer を packages で公開する
#
# 注意:
#   - 既存ファイル（flake.nix / hosts/ / terraform/ など）は変更しないこと
#   - 認証情報・秘密鍵はハードコードしない（公開鍵のみ）
#   - 静的 IP は terraform apply 後に確定するため、未確定なら wan.ipv4 を null のまま
#     にして ISO をビルドし、起動後に `install-nixos.sh network` で手動設定できる
{
  config,
  lib,
  modulesPath,
  ...
}:

{
  imports = [
    # インストーラ ISO のベース（iso-image + インストーラツール群）。
    # - nixos-install / nixos-generate-config / parted 等が同梱される
    # - isoImage.* オプションが定義される
    # - ライブ環境のファイルシステム（tmpfs ルート + squashfs ストア）が設定される
    #
    # 注: system.build.images.iso-installer バリアントでも同じモジュールが付加されるが、
    #     重複 import は NixOS モジュールシステムが冪等にマージするため問題ない。
    #     直接 import しておくことで nixosConfigurations.<name>.config.system.build.isoImage
    #     でも ISO をビルドできる。
    "${modulesPath}/installer/cd-dvd/installation-cd-base.nix"

    ./network.nix
    ./ssh.nix
    ./memory.nix
    ./installer-tools.nix
  ];

  options.conoha.installer = {
    hostName = lib.mkOption {
      type = lib.types.str;
      default = "conoha-installer";
      description = "インストーラ（ライブ環境）のホスト名。";
    };

    # ネットワーク関連。ConoHa VPS は DHCP を提供しないため静的設定が基本。
    interface = lib.mkOption {
      type = lib.types.str;
      default = "eth0";
      description = ''
        インストーラが使うネットワークインターフェース名。
        ConoHa VPS は virtio NIC で、予測可能なインターフェース名を無効化している
        ため通常は eth0。起動後に `ip link` で確認し、違う名前なら変更すること。
      '';
    };

    wan = {
      ipv4 = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        example = "203.0.113.10";
        description = ''
          ConoHa から割り当てられた IPv4 アドレス。
          `terraform apply` 後に `terraform output -json torii_chan_addresses` で
          確認して指定する。null のままビルドすると静的 IP は設定されず、
          起動後に `install-nixos.sh network` で手動設定するモードになる。
        '';
      };

      prefixLength = lib.mkOption {
        type = lib.types.int;
        default = 24;
        example = 32;
        description = "IPv4 アドレスのプレフィックス長。ConoHa の割当に合わせて指定。";
      };

      gateway = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        example = "203.0.113.1";
        description = "デフォルトゲートウェイの IPv4 アドレス。";
      };

      nameservers = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [
          "1.1.1.1"
          "8.8.8.8"
        ];
        description = "DNS ネームサーバーのリスト。";
      };
    };

    # SSH ログインを許可する公開鍵（authorizedKeys）。
    authorizedKeys = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [
        # t3u の公開鍵（公開情報。秘密鍵は含めない）
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIB3QNRSxPauISsWs7nob0tXfxjTsMpBEIYIjasRD9bpT t3u@BrokenPC"
      ];
      description = "インストーラの root に登録する SSH 公開鍵のリスト。";
    };

    install = {
      disk = lib.mkOption {
        type = lib.types.str;
        default = "/dev/vda";
        description = ''
          インストール先ディスク（install-nixos.sh のデフォルト値）。
          ConoHa の 30GB ブートボリュームは通常 /dev/vda。
        '';
      };

      swapSize = lib.mkOption {
        type = lib.types.str;
        default = "1G";
        description = "インストール時に作成するスワップファイルのサイズ。";
      };
    };
  };

  config = {
    networking.hostName = config.conoha.installer.hostName;

    # ISO のボリュームラベル / ブートメニュー名（volumeID は 32 文字制限）。
    # installation-cd-base（iso-image.nix）を直接 import しているため、
    # ベース設定の時点で isoImage オプションが存在する。
    isoImage = {
      volumeID = "conoha-installer";
      appendToMenuLabel = " ConoHa Installer";
    };
  };
}
