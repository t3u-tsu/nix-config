{ config, lib, ... }:
{
  imports = [
    ./boot.nix
    ./security.nix
    ./ssh.nix
    ./user.nix
  ];

  config = {
    my.services.monitoring.enable = lib.mkDefault true;
  };
}
