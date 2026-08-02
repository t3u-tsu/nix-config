{
  config,
  lib,
  pkgs,
  ...
}:

with lib;
let
  username = config.my.user.name;
  # Map the hostname to the SOPS secret key prefix (e.g. "torii-chan" -> "torii_chan")
  hostKey = builtins.replaceStrings [ "-" ] [ "_" ] (lib.toLower config.networking.hostName);
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
      default = [ ];
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
        # Password hashes are managed via SOPS (see nixos/security/sops.nix)
        hashedPasswordFile = config.sops.secrets."${hostKey}_t3u_password_hash".path;
        openssh.authorizedKeys.keys = config.my.user.authorizedKeys;
      };

      users.root = {
        hashedPasswordFile = config.sops.secrets."${hostKey}_root_password_hash".path;
        openssh.authorizedKeys.keys = config.my.user.authorizedKeys;
      };
    };
  };
}
