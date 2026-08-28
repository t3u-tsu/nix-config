{ config, lib, ... }:
{
  imports = [
    ./boot.nix
    ./security.nix
    ./ssh.nix
  ];

  config = {
    my = {
      user = {
        # NOTE: keep "wheel" here — setting user.extraGroups replaces the base
        # default ([ "wheel" ] in nixos/base/user.nix), so omitting it removes
        # sudo access for the primary user.
        extraGroups = [
          "wheel"
          "video"
          "render"
        ];
      };

      # Physical PC/server tools (smartmontools, nvme-cli)
      hardware.pc-tools.enable = true;
    };
  };
}
