# hosts/torii-chan/installer-common.nix
#
# インストーラ（stage: installer）共通設定。SBC SD イメージ（sd-installer.nix）と
# VPS インストーラ ISO（vps-installer.nix）の両方で共用する（DRY）。
#
# 本番（stage: production）とは逆の性質を持つ:
#   - 本番サービス（gateway: Nebula / DDNS / NAT）を無効化
#   - 本番シークレット（SOPS 管理のパスワードハッシュ）を焼き込まない
#   - 一時パスワード（build-*.sh が --impure ビルドで注入）または公開鍵でログイン
#   - sshd はプラットフォームに応じて「緩さ」を調整する
#     （SBC = LAN 内なので一時パスワード + パスワード認証可 / VPS = 公開 IP なので鍵のみ）
{
  config,
  lib,
  ...
}:

with lib;

let
  cfg = config.my.installer;
  username = config.my.user.name;
  # ホスト名を SOPS の secret 名プレフィックス（例: "torii-chan" -> "torii_chan"）に変換
  hostKey = builtins.replaceStrings [ "-" ] [ "_" ] (lib.toLower config.networking.hostName);

  # build-*.sh が --impure ビルドで環境変数として渡す一時パスワードハッシュ。
  # 通常（純粋評価）のビルドでは空文字になり、一時パスワードは設定されない。
  envTempPasswordHash = builtins.getEnv "TORII_INSTALLER_TEMP_PASSWORD_HASH";
  # 環境変数（自動発行）を優先し、なければオプション指定（手動）を使う。
  tempPasswordHash =
    if envTempPasswordHash != "" then envTempPasswordHash else cfg.temporaryPasswordHash;
in
{
  options.my.installer = {
    enable = mkEnableOption "installer stage: temporary provisioning without production services";

    hostName = mkOption {
      type = types.str;
      default = "torii-chan";
      description = "Hostname used by the installer environment.";
    };

    temporaryPasswordHash = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = ''
        Temporary password hash (SHA-512) for the installer environment.
        Usually injected by build-*.sh via TORII_INSTALLER_TEMP_PASSWORD_HASH
        (nix build --impure). When null, no password is set (SSH key only).
      '';
    };

    authorizedKeys = mkOption {
      type = types.listOf types.str;
      default = [
        # t3u の公開鍵（公開情報。秘密鍵は含めない）
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIB3QNRSxPauISsWs7nob0tXfxjTsMpBEIYIjasRD9bpT t3u@BrokenPC"
      ];
      description = "SSH public keys for the installer root user.";
    };

    allowPasswordAuthentication = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Allow SSH password authentication. LAN-only installers (SBC) can enable
        this for convenience together with the temporary password; installers
        exposed to the internet (VPS) should keep it disabled (key-only).
      '';
    };

    firewallOpenPorts = mkOption {
      type = types.listOf types.int;
      default = [ 22 ];
      description = "TCP ports opened by the installer firewall.";
    };
  };

  config = mkIf cfg.enable {
    # --- 本番サービスを無効化 ---
    # hosts/torii-chan/default.nix が my.services.gateway.enable = true を設定する
    # ため、mkForce で無効化する（Nebula / DDNS / NAT は実行しない）。
    my.services.gateway.enable = lib.mkForce false;

    networking.hostName = cfg.hostName;

    # --- ファイアウォール（プロビジョニング用に 22 のみ） ---
    networking.firewall = {
      enable = true;
      allowedTCPPorts = cfg.firewallOpenPorts;
      allowedUDPPorts = [ ];
      logRefusedConnections = false;
    };

    # --- SSH（プロビジョニング用） ---
    # インストーラでは root の authorizedKeys に公開鍵を焼き込み、一時パスワード
    # （指定時のみ）でもログインできるようにする。
    services.openssh = {
      enable = true;
      settings = {
        PermitRootLogin = "prohibit-password";
        PasswordAuthentication = cfg.allowPasswordAuthentication;
        KbdInteractiveAuthentication = false;
      };
    };

    # --- 一時パスワード / SOPS 分離 ---
    # 本番のパスワードハッシュ（SOPS 管理）をインストーラに焼き込まない。
    # neededForUsers を無効化して起動時復号を止め、ライブ環境のユーザーには
    # 一時パスワード（指定時のみ）を設定する。本番化後のシステムは通常の
    # nixos-rebuild（SOPS 管理の hashedPasswordFile）に切り替わる。
    sops.secrets = {
      "${hostKey}_${username}_password_hash".neededForUsers = lib.mkForce false;
      "${hostKey}_root_password_hash".neededForUsers = lib.mkForce false;
    };

    users.users = {
      root = {
        openssh.authorizedKeys.keys = cfg.authorizedKeys;
        hashedPasswordFile = lib.mkForce null;
        hashedPassword = lib.mkIf (tempPasswordHash != null) (lib.mkForce tempPasswordHash);
      };
      ${username} = {
        hashedPasswordFile = lib.mkForce null;
        hashedPassword = lib.mkIf (tempPasswordHash != null) (lib.mkForce tempPasswordHash);
      };
    };
  };
}
