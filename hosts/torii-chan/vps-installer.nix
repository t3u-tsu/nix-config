# hosts/torii-chan/vps-installer.nix - ConoHa VPS (512MB) 用 カスタム NixOS インストーラ ISO 設定
#
# torii-chan のフェイルオーバー VPS（ConoHa VPS g2l-t-c1m512 = 1 vCPU / 512MB RAM
# / 30GB ボリューム、x86_64）に NixOS をインストールするための「SSH から操作できる
# インストーラ ISO」を生成する NixOS モジュール。
#
# sd-image-installer.nix（SBC 用 SD イメージ）と同様に、ホスト torii-chan の
# 「インストーラ」レイヤーとして hosts/torii-chan/ 配下に置く。
#
# 標準の NixOS インストーラ ISO は sshd 自体は有効だが、ログインにはコンソールで
# パスワード設定か authorized_keys の追加が必要で、ConoHa は DHCP を提供しない。
# そのため VNC コンソールでの手作業（遅い・非対話化が難しい）に依存していた。
# 本モジュールは以下を組み込んで、SSH だけでインストールを完結させる:
#
#   - services.openssh 有効化 + root の authorizedKeys（公開鍵のみ・パスワード認証無効）
#   - 静的 IP 設定（ConoHa は DHCP 無効。IP は conoha.installer.wan で指定）
#   - 512MB 向け低メモリ設定（zram、シリアルコンソール、OOM 対策）
#   - nixos-install 自動化スクリプト install-nixos（同梱・PATH に追加）
#
# ビルド:
#   nix build .#nixosConfigurations.torii-chan-vps-installer.config.system.build.images.iso-installer
#   （または nix build .#torii-chan-vps-iso）
#
# 静的 IP は terraform apply 後に確定するため、未確定なら conoha.installer.wan.ipv4 を
# null のままビルドし、起動後に `install-nixos.sh network` で手動設定できる。
# 認証情報・秘密鍵はハードコードしない（公開鍵のみ）。
{
  config,
  lib,
  modulesPath,
  pkgs,
  ...
}:

let
  cfg = config.conoha.installer;
in
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
  ];

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
    # インストーラ ISO では gateway 役割（WireGuard / DDNS / NAT）は実行しない。
    # hosts/torii-chan/default.nix が my.services.gateway.enable = true を設定する
    # ため、mkForce で無効化する（hostName 等の衝突も解消）。
    my.services.gateway.enable = lib.mkForce false;
    networking.hostName = cfg.hostName;

    # ISO のボリュームラベル / ブートメニュー名（volumeID は 32 文字制限）。
    # installation-cd-base（iso-image.nix）を直接 import しているため、
    # ベース設定の時点で isoImage オプションが存在する。
    isoImage = {
      volumeID = "conoha-installer";
      appendToMenuLabel = " ConoHa Installer";
    };

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

      # インストーラはパブリック IP に直接晒されるため、22/tcp のみ開放する
      firewall = {
        enable = true;
        allowedTCPPorts = [ 22 ];
        logRefusedConnections = false;
      };
    };

    # 静的 IP 未指定時のビルド時警告（VNC コンソールからの手動設定が必要になる旨）
    warnings = lib.optional (cfg.wan.ipv4 == null) ''
      conoha.installer.wan.ipv4 が未設定です。この ISO は静的 IP が設定されないため、
      SSH 接続には起動後に VNC コンソールから次を実行してネットワークを設定してください:
        install-nixos.sh network
      または、terraform apply 後に IP を確定してから ISO をビルドし直してください。
    '';

    # --- SSH（旧 nixos/installer/ssh.nix） ---
    # 標準の NixOS インストーラ ISO（profiles/installation-device.nix）は sshd を
    # 有効化するが（mkDefault true）、ログインには「コンソールでパスワードを設定する」
    # か「authorized_keys を手で追加する」必要がある。ConoHa ではコンソールは VNC
    # のみで非対話化が難しいため、本モジュールで root の authorizedKeys に公開鍵を
    # 焼き込み、パスワード認証を無効化して「鍵だけで SSH ログインできる」状態にする。
    services.openssh = {
      enable = true; # installation-device.nix の mkDefault true を明示化
      settings = {
        # root は鍵のみ許可（パスワード / 空パスワードは不可）
        PermitRootLogin = "prohibit-password";
        PasswordAuthentication = false;
        KbdInteractiveAuthentication = false;

        # SSH セッションの切断防止（VPS のネットワークは不安定になりがち）
        ClientAliveInterval = 60;
        ClientAliveCountMax = 3;
      };
    };

    # インストーラ操作用: root の authorizedKeys に公開鍵を登録する。
    # （インストーラの初期パスワードは設定しない。SSH は鍵のみで接続する）
    users.users.root.openssh.authorizedKeys.keys = cfg.authorizedKeys;

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

    # --- インストール補助ツール（旧 nixos/installer/installer-tools.nix） ---
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
