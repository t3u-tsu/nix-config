{
  config,
  lib,
  inputs,
  ...
}:

{
  imports = [
    inputs.chaotic.nixosModules.nyx-overlay
  ];

  config = {
    chaotic.nyx.overlay.enable = lib.mkDefault config.my.services.desktop.full.enable;

    my = {
      services.desktop.enable = true;
      hardware.pc-tools.enable = true;
      dev-tools.enable = true;
    };

    home-manager.users.${config.my.user.name} = {
      imports = [
        ../../../home/desktop
      ];

      my.home.desktop.enable = true;
    };
  };
}
