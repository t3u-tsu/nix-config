{ lib, ... }:

{
  imports = [
    ./boot.nix
    ./security.nix
    ./ssh.nix
  ];

  config = {
    my = {
      user.extraGroups = [
        "video"
        "render"
      ];

      hardware.pc-tools.enable = true;

      services.emergencySsh.enable = lib.mkDefault true;
    };
  };
}
