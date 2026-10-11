{
  config,
  lib,
  ...
}:

{
  imports = [
    ./proxy.nix
    ./servers
  ];

  options.my.services.minecraft = {
    enable = lib.mkEnableOption "Minecraft server services";
  };

  config = lib.mkIf config.my.services.minecraft.enable {
    services.minecraft-servers = {
      enable = true;
      eula = true;
    };

    sops.secrets = {
      minecraft_forwarding_secret = {
        sopsFile = ../../../secrets/services/minecraft.yaml;
        owner = "minecraft";
        group = "minecraft";
        mode = "0400";
      };

      nitac23s_rcon_password = {
        sopsFile = ../../../secrets/services/minecraft.yaml;
        owner = "minecraft";
        group = "minecraft";
        mode = "0400";
      };
    };
  };
}
