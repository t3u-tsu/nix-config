{ config, pkgs, lib, inputs, ... }:

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
      eula = true; # 同意
    };

    # Automatically register nvfetcher update task if auto-update is enabled
    my.updateHub.client.nvfetcher = [
      (inputs.self.lib.autoUpdate.mkNvfetcherTask "services/minecraft/plugins")
    ];
  };
}
