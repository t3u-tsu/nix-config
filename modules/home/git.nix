{ config, pkgs, ... }:

{
  programs.git = {
    enable = true;

    # Git User Configuration
    settings = {
      credential.helper = "${pkgs.gh}/bin/gh auth git-credential";
      user.name = "t3u-tsu";
      user.email = "t3u@t3u.uk";
      user.signingkey = "9FC270ACC3631FB4";
      core.editor = "vim";
      init.defaultBranch = "main";

      # Always sign commits with GPG
      commit.gpgsign = true;
      gpg.format = "openpgp";
    };
  };

  # GPG Configuration
  programs.gpg = {
    enable = true;
  };

  # SOPS secret for GPG private key
  # This will only be decrypted if the user has the required age key
  sops.secrets.gpg_private_key = {
    sopsFile = ../../secrets/services/signing.yaml;
  };

  # Automatically import the GPG private key from SOPS if available
  home.activation.importGpgKey = config.lib.dag.entryAfter [ "writeBoundary" ] ''
    GPG_KEY_PATH="${config.sops.secrets.gpg_private_key.path}"
    if [ -f "$GPG_KEY_PATH" ]; then
      $DRY_RUN_CMD ${pkgs.gnupg}/bin/gpg --batch --import "$GPG_KEY_PATH" || true
    fi
  '';
}
