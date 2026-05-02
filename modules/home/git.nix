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

  # GPG Agent for passphrase management
  services.gpg-agent = {
    enable = true;
    pinentry.package = pkgs.pinentry-qt;
    enableZshIntegration = true;
  };

  programs.delta = {
    enable = true;
    enableGitIntegration = true;
    options = {
      navigate = true;
      light = false;
      line-numbers = true;
    };
  };

  # Automatically import the GPG private key from SOPS if available
  # Note: The secret should be placed at /run/secrets/gpg_private_key by SOPS
  home.activation.importGpgKey = config.lib.dag.entryAfter [ "writeBoundary" ] ''
    if [ -f /run/secrets/gpg_private_key ]; then
      $DRY_RUN_CMD ${pkgs.gnupg}/bin/gpg --batch --import /run/secrets/gpg_private_key || true
    fi
  '';
}
