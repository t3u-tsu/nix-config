{ config, ... }:

{
  home-manager.users.${config.my.user.name} = {
    home.stateVersion = config.system.stateVersion;

    imports = [
      ./shell.nix
      ./starship.nix
      ./atuin.nix
      ./git.nix
      ./cli-tools.nix
      ./ssh.nix
    ];

    # Command-not-found & comma (,) integration
    programs.nix-index.enable = true;
    programs.nix-index-database.comma.enable = true;

    # SOPS configuration for Home-manager
    sops = {
      # 宣言的に ~/.config/sops/age/keys.txt に age 秘密鍵を自動生成・配置
      age.keyFile = "/home/${config.my.user.name}/.config/sops/age/keys.txt";
      age.sshKeyPaths = [ "/home/${config.my.user.name}/.ssh/id_ed25519" ];
      age.generateKey = false;
    };
  };
}
