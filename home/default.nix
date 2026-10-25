{ config, ... }:

{
  home-manager.users.${config.my.user.name} = { osConfig, ... }: {
    home.stateVersion = osConfig.system.stateVersion;

    imports = [
      ./agenix.nix
      ./shell
      ./programs
    ];
  };
}
