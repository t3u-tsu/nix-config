{ config, pkgs, ... }:

{
  programs = {
    git = {
      enable = true;

      # credential.helper comes from desktop/dev-tools/git-tools.nix; gh is
      # desktop-only because it does not cross-compile for aarch64.
      settings = {
        user = {
          name = "t3u-tsu";
          email = "t3u@t3u.uk";
          signingkey = "9FC270ACC3631FB4";
        };
        core.editor = "vim";
        init.defaultBranch = "main";

        commit.gpgsign = true;
        gpg.format = "openpgp";

        pull.rebase = true;
      };
    };

    gpg = {
      enable = true;
    };
  };
}
