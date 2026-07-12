{ config, lib, ... }:

let
  username = config.my.user.name;
  hostKey = builtins.replaceStrings [ "-" ] [ "_" ] (lib.toLower config.networking.hostName);
in
{
  users = {
    mutableUsers = false;

    users.${username} = {
      isNormalUser = true;
      extraGroups = [
        "wheel"
        "video"
        "render"
      ];
      hashedPasswordFile = config.sops.secrets."${hostKey}_t3u_password_hash".path;
      openssh.authorizedKeys.keys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIB3QNRSxPauISsWs7nob0tXfxjTsMpBEIYIjasRD9bpT t3u@BrokenPC"
      ];
    };

    users.root = {
      hashedPasswordFile = config.sops.secrets."${hostKey}_root_password_hash".path;
      openssh.authorizedKeys.keys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIB3QNRSxPauISsWs7nob0tXfxjTsMpBEIYIjasRD9bpT t3u@BrokenPC"
      ];
    };
  };
}
