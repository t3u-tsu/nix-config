{ config, lib, ... }:
{
  imports = [
    ./boot.nix
    ./security.nix
    ./ssh.nix
  ];

  config = {
    my = {
      # Comin automatic deployment (default: enabled)
      services.deployment.comin.enable = lib.mkDefault true;

      # Common server user configuration (base/user.nix handles users.*)
      user = {
        extraGroups = [
          "video"
          "render"
        ];
        authorizedKeys = [
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIB3QNRSxPauISsWs7nob0tXfxjTsMpBEIYIjasRD9bpT t3u@BrokenPC"
        ];
      };

      # Physical PC/server tools (smartmontools, nvme-cli)
      hardware.pc-tools.enable = true;
    };
  };
}
