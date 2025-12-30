{ config, pkgs, lib, ... }:

{
  imports = [
    ./proxy.nix
    ./servers
  ];

  services.minecraft-servers = {
    enable = true;
    eula = true; # 同意
  };
}
