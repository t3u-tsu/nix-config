{ config, ... }:

{
  home-manager.users.${config.my.user.name} = { osConfig, ... }: {
    home.stateVersion = osConfig.system.stateVersion;

    imports = [
      ./sops.nix
      ./shell
      ./programs
    ];
  };
}
