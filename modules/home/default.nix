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
      age.sshKeyPaths = [ "/home/${config.my.user.name}/.ssh/id_ed25519" ];
      age.generateKey = false;
    };
  };
}
