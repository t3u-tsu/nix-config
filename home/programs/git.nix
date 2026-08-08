{ config, pkgs, ... }:

{
  programs = {
    git = {
      enable = true;

      # Git User Configuration (credential helper is set per-profile
      # in home/default.nix; gh is desktop-only because it does not
      # cross-compile for aarch64)
      settings = {
        user = {
          name = "t3u-tsu";
          email = "t3u@t3u.uk";
          signingkey = "9FC270ACC3631FB4";
        };
        core.editor = "vim";
        init.defaultBranch = "main";

        # Always sign commits with GPG
        commit.gpgsign = true;
        gpg.format = "openpgp";

        # Rebase on pull to keep history linear
        pull.rebase = true;
      };
    };

    # GPG Configuration
    gpg = {
      enable = true;
    };
  };
}
