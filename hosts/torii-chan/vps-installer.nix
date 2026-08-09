# hosts/torii-chan/vps-installer.nix - ConoHa VPS (512MB) 用 カスタム NixOS インストーラ ISO 設定
#
# torii-chan のフェイルオーバー VPS（ConoHa VPS g2l-t-c1m512 = 1 vCPU / 512MB RAM
# / 30GB ボリューム、x86_64）に NixOS をインストールするための「SSH から操作できる
# インストーラ ISO」を生成する NixOS モジュール。
#
# sd-installer.nix（SBC 用 SD イメージ）と stage: installer の共通設定
# （installer-common.nix）を共有する。本モジュールは VPS 固有の差分のみを担う:
#   - ISO 形式（image.modules."iso-installer"）
#   - 静的 IP 設定（ConoHa は DHCP 無効。IP は conoha.installer.wan で指定）
#   - 512MB 向け低メモリ設定（zram、シリアルコンソール、OOM 対策）
#   - nixos-install 自動化スクリプト install-nixos（同梱・PATH に追加）
#
# 認証まわり（一時パスワード / SSH 公開鍵 / SOPS 分離 / 本番サービス無効化）は
# installer-common.nix が提供する。VPS は公開 IP に直接晒されるため SSH は鍵のみ。
#
# ビルド（一時パスワード自動発行）:
#   ./hosts/torii-chan/build-vps-iso.sh
#   （nixosConfigurations には登録しない。nix flake check が ISO を通常の
#    ブート可能システムとして検証して失敗するため、packages としてのみ公開）
#
# 静的 IP は terraform apply 後に確定するため、未確定なら conoha.installer.wan.ipv4 を
# null のままビルドし、起動後に `install-nixos.sh network` で手動設定できる。
{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.conoha.installer;
in
{
  imports = [
    ./installer-common.nix
  ];

  # NOTE: installation-cd-base.nix は直接 import しない。
  # system.build.images.iso-installer が image.modules 経由で自動付加する
  # （nixpkgs/modules/image/images.nix の image.format = "iso-installer"）。
  # 直接 import すると system.build.image がトップレベルに定義され、
  # system.build.images と衝突する警告（build.image vs images）が出る。
  # isoImage.* の設定は image.modules."iso-installer" で行う（下記）。

  options.conoha.installer = {
    hostName = lib.mkOption {
      type = lib.types.str;
      default = "torii-chan";
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
    # --- インストーラ共通（installer-common.nix） ---
    # 本番サービス無効化 / 一時パスワード / SOPS 分離 / sshd 設定を提供する。
    # 一時パスワードは build-vps-iso.sh が TORII_INSTALLER_TEMP_PASSWORD_HASH 経由で
    # 注入する（nix build --impure）。VPS は公開 IP のため SSH は鍵のみ。
    my.installer = {
      enable = true;
      allowPasswordAuthentication = false;
    };

    networking.hostName = cfg.hostName;

    # --- ネットワーク（旧 nixos/installer/network.nix） ---
    # ConoHa VPS は DHCP を提供しないため、静的 IP を明示設定する。
    # IP は terraform apply 後に確定する（terraform/outputs.tf の
    # torii_chan_addresses を参照）。ISO ビルド時点で未確定なら
    # conoha.installer.wan.ipv4 = null のままビルドし、起動後に
    # `install-nixos.sh network` で手動設定するフォールバックを用意する。
    networking = {
      # スクリプト式ネットワーク（systemd-networkd / NetworkManager は使わない）
      useDHCP = false;
      # virtio NIC を eth0 として扱う（systemd の予測可能な命名を無効化）
      usePredictableInterfaceNames = false;
      networkmanager.enable = lib.mkForce false; # installation-device.nix が有効化するため mkForce で無効化

      # 静的 IP 設定（wan.ipv4 が指定された場合のみ有効）
      interfaces.${cfg.interface} = lib.mkIf (cfg.wan.ipv4 != null) {
        useDHCP = false;
        ipv4.addresses = [
          {
            address = cfg.wan.ipv4;
            prefixLength = cfg.wan.prefixLength;
          }
        ];
      };

      defaultGateway = lib.mkIf (cfg.wan.gateway != null) cfg.wan.gateway;
      nameservers = cfg.wan.nameservers;
    };

    # 静的 IP 未指定時のビルド時警告（VNC コンソールからの手動設定が必要になる旨）
    warnings = lib.optional (cfg.wan.ipv4 == null) ''
      conoha.installer.wan.ipv4 が未設定です。この ISO は静的 IP が設定されないため、
      SSH 接続には起動後に VNC コンソールから次を実行してネットワークを設定してください:
        install-nixos.sh network
      または、terraform apply 後に IP を確定してから ISO をビルドし直してください。
    '';

    # --- ISO のボリュームラベル / ブートメニュー名 ---
    image.modules."iso-installer" = {
      isoImage = {
        volumeID = "conoha-installer";
        appendToMenuLabel = " ConoHa Installer";
      };
    };

    # --- 低メモリチューニング（旧 nixos/installer/memory.nix） ---
    # ライブ環境の /nix/store は squashfs + tmpfs オーバーレイで構成され、
    # nixos-install 時のキャッシュ展開で RAM を消費する。512MB では OOM しやすい
    # ため、zram でメモリ不足を吸収し、スワップを積極利用する。
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

    # --- インストール補助ツール ---
    # nixos-install / nixos-generate-config / parted / gptfdisk は標準のインストーラ
    # ISO（module-list.nix の installer/tools/tools.nix と profiles/base.nix）に
    # 既に含まれるため、ここでは再追加しない。
    environment.systemPackages = [
      # インストール自動化スクリプト（install-nixos として PATH に追加）
      (pkgs.writeShellScriptBin "install-nixos" (builtins.readFile ./install-nixos.sh))

      # 手動フォールバックやファイル転送に使うツール
      pkgs.curl
    ];
  };
}
