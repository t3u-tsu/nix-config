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

  options.my.desktop = {
    full.enable = lib.mkEnableOption "Full desktop experience (gaming, Unity/Distrobox, creative, media, office, AI/hardware dev tools)";
  };

  config = {
    # Chaotic-Nyx overlay supplies packages absent from nixpkgs (mangohud_git,
    # gamescope_git, etc.) used by the full gaming stack; only apply it when
    # the full desktop is enabled to keep lightweight cores cheap to evaluate.
    chaotic.nyx.overlay.enable = lib.mkDefault config.my.desktop.full.enable;

    my = {
      services.desktop.enable = true;
      services.desktop.full.enable = lib.mkDefault config.my.desktop.full.enable;

      hardware.pc-tools.enable = true;
      dev-tools.enable = true;
    };

    home-manager.users.${config.my.user.name} = {
      imports = [
        ../../../home/desktop
      ];

      my.home.desktop.enable = true;
      my.home.desktop.full.enable = lib.mkDefault config.my.desktop.full.enable;
    };
  };
}
