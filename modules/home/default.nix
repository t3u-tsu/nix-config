{ config, ... }:

{
  home-manager.users.${config.my.user.name} = {
    home.stateVersion = config.system.stateVersion;

    imports = [
      ./shell.nix
      ./starship.nix
      ./atuin.nix
      ./git.nix
      ./ssh.nix
      ./cli-tools.nix
    ];

    # Command-not-found & comma (,) integration
    programs.nix-index.enable = true;
    programs.nix-index-database.comma.enable = true;
  };
}
