# nixos/installer/ssh.nix - インストーラ ISO の SSH 設定
#
# 標準の NixOS インストーラ ISO（profiles/installation-device.nix）は sshd を
# 有効化するが（mkDefault true）、ログインには「コンソールでパスワードを設定する」
# か「authorized_keys を手で追加する」必要がある。ConoHa ではコンソールは VNC
# のみで非対話化が難しいため、本モジュールで root の authorizedKeys に公開鍵を
# 焼き込み、パスワード認証を無効化して「鍵だけで SSH ログインできる」状態にする。
{
  config,
  lib,
  ...
}:

let
  cfg = config.conoha.installer;
in
{
  config = {
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
  };
}
