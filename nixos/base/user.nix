{
  config,
  lib,
  pkgs,
  ...
}:

let
  username = config.my.user.name;
in
{
  options.my.user = {
    name = lib.mkOption {
      type = lib.types.str;
      default = "t3u";
      description = "The primary user of the system";
    };
    extraGroups = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ "wheel" ];
      description = "Additional groups for the primary user";
    };
    authorizedKeys = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIB3QNRSxPauISsWs7nob0tXfxjTsMpBEIYIjasRD9bpT t3u@BrokenPC"
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDcgVKvJVkA7KBmdO7ogwb5v9f1qUGOCiKu1CHpOLjYU t3u@x1c7"
      ];
      description = "SSH public keys for the primary user and root";
    };
    shell = lib.mkOption {
      type = lib.types.package;
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
        extraGroups = lib.unique ([ "wheel" ] ++ config.my.user.extraGroups);
        shell = config.my.user.shell;
        hashedPasswordFile = config.age.secrets.user_password_hash.path;
        openssh.authorizedKeys.keys = lib.mkIf config.services.openssh.enable config.my.user.authorizedKeys;
      };

      users.root = {
        openssh.authorizedKeys.keys = lib.mkIf config.services.openssh.enable config.my.user.authorizedKeys;
      };
    };
  };
}
