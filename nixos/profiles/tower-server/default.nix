{ config, lib, ... }:
{
  imports = [
    ./boot.nix
    ./security.nix
    ./ssh.nix
    ./user.nix
  ];

  config = {
    # Comin automatic deployment (default: enabled)
    my.services.deployment.comin.enable = lib.mkDefault true;
  };
}
