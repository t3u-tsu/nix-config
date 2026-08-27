{ config, ... }:

let
  username = config.my.user.name;
  systemStateVersion = config.system.stateVersion;
in
{
  home-manager.users.${username} = { config, pkgs, ... }: {
    home = {
      stateVersion = systemStateVersion;

      # At activation, safely convert and export the age private key from the daily SSH key
      activation.generateAgeKey = config.lib.dag.entryBetween [ "writeBoundary" ] [ "setupSecrets" ] ''
        if [ ! -f "/home/${username}/.config/sops/age/keys.txt" ]; then
          $DRY_RUN_CMD mkdir -p "/home/${username}/.config/sops/age"
          $DRY_RUN_CMD ${pkgs.ssh-to-age}/bin/ssh-to-age -private-key -i "/home/${username}/.ssh/id_ed25519" > "/home/${username}/.config/sops/age/keys.txt" || true
        fi
      '';
    };

    imports = [
      ./shell/shell.nix
      ./shell/pure.nix
      ./shell/atuin.nix
      ./programs/git.nix
      ./programs/cli-tools.nix
      ./programs/ssh.nix
      ./programs/llama.nix
    ];

    programs = {
      nix-index.enable = true;
    };

    sops = {
      age = {
        keyFile = "/home/${username}/.config/sops/age/keys.txt";
        sshKeyPaths = [ "/home/${username}/.ssh/id_ed25519" ];
        generateKey = false;
      };
    };
  };
}
