{
  config,
  ...
}:

{
  config = {

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
