{ config, ... }:

let
  username = config.my.user.name;
  systemStateVersion = config.system.stateVersion;
in
{
  home-manager.users.${username} = { config, pkgs, ... }: {
    home = {
      stateVersion = systemStateVersion;

      # アクティベーション時に日常用 SSH 鍵から age 秘密鍵を安全に変換・出力する設定
      activation.generateAgeKey = config.lib.dag.entryBetween [ "writeBoundary" ] [ "setupSecrets" ] ''
        if [ ! -f "/home/${username}/.config/sops/age/keys.txt" ]; then
          $DRY_RUN_CMD mkdir -p "/home/${username}/.config/sops/age"
          $DRY_RUN_CMD ${pkgs.ssh-to-age}/bin/ssh-to-age -private-key -i "/home/${username}/.ssh/id_ed25519" > "/home/${username}/.config/sops/age/keys.txt" || true
        fi
      '';
    };

    imports = [
      ./shell/shell.nix
      ./shell/starship.nix
      ./shell/atuin.nix
      ./programs/git.nix
      ./programs/cli-tools.nix
      ./programs/ssh.nix
    ];

    # Command-not-found & comma (,) integration
    programs = {
      nix-index.enable = true;
      nix-index-database.comma.enable = true;
    };

    # SOPS configuration for Home-manager
    sops = {
      # 宣言的に ~/.config/sops/age/keys.txt に age 秘密鍵を自動生成・配置
      age = {
        keyFile = "/home/${username}/.config/sops/age/keys.txt";
        sshKeyPaths = [ "/home/${username}/.ssh/id_ed25519" ];
        generateKey = false;
      };
    };
  };
}
