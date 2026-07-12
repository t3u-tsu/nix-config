{ config, pkgs, ... }:

{
  programs = {
    git = {
      enable = true;

      # Git User Configuration
      settings = {
        credential.helper = "${pkgs.gh}/bin/gh auth git-credential";
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
      };
    };

    # GPG Configuration
    gpg = {
      enable = true;
    };
  };
}
