{
  config,
  lib,
  pkgs,
  ...
}:

with lib;
let
  username = config.my.user.name;
in
{

  options.my.user = {
    name = mkOption {
      type = types.str;
      default = "t3u";
      description = "The primary user of the system";
    };
    extraGroups = mkOption {
      type = types.listOf types.str;
      default = [ "wheel" ];
      description = "Additional groups for the primary user";
    };
    authorizedKeys = mkOption {
      type = types.listOf types.str;
      default = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIB3QNRSxPauISsWs7nob0tXfxjTsMpBEIYIjasRD9bpT t3u@BrokenPC"
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDcgVKvJVkA7KBmdO7ogwb5v9f1qUGOCiKu1CHpOLjYU t3u@x1c7"
      ];
      description = "SSH public keys for the primary user and root";
    };
    shell = mkOption {
      type = types.package;
      default = pkgs.zsh;
      description = "Login shell for the primary user";
    };
  };

  config = {
    users = {
      mutableUsers = false;

      users.${username} = {
        isNormalUser = true;
        description = username;
        extraGroups = config.my.user.extraGroups;
        shell = config.my.user.shell;
        hashedPasswordFile = config.age.secrets.user_password_hash.path;
        openssh.authorizedKeys.keys = config.my.user.authorizedKeys;
      };

      users.root = {
        openssh.authorizedKeys.keys = config.my.user.authorizedKeys;
      };
    };
  };
}
