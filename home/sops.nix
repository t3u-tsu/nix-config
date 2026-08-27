{ config, pkgs, ... }:

{
  home.activation.generateAgeKey =
    config.lib.dag.entryBetween [ "writeBoundary" ] [ "setupSecrets" ]
      ''
        if [ ! -f "${config.home.homeDirectory}/.config/sops/age/keys.txt" ]; then
          $DRY_RUN_CMD mkdir -p "${config.home.homeDirectory}/.config/sops/age"
          $DRY_RUN_CMD ${pkgs.ssh-to-age}/bin/ssh-to-age -private-key -i "${config.home.homeDirectory}/.ssh/id_ed25519" > "${config.home.homeDirectory}/.config/sops/age/keys.txt" || true
        fi
      '';

  sops = {
    age = {
      keyFile = "${config.home.homeDirectory}/.config/sops/age/keys.txt";
      sshKeyPaths = [ "${config.home.homeDirectory}/.ssh/id_ed25519" ];
      generateKey = false;
    };
  };
}
