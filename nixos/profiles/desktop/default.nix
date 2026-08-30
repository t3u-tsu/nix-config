{
  config,
  inputs,
  ...
}:

{
  imports = [
    inputs.chaotic.nixosModules.nyx-overlay
  ];

  config = {
    my = {
      # Aggregate system services
      services.desktop.enable = true;

      # System-side developer/hardware tooling for user workstations
      hardware.pc-tools.enable = true;
      dev-tools.enable = true;
    };

    # Wire the home-manager desktop modules for the primary user
    home-manager.users.${config.my.user.name} = {
      imports = [
        ../../../home/desktop
      ];

      my.home.desktop.enable = true;
    };
  };
}
