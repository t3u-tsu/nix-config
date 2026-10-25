_:

{
  programs.git = {
    enable = true;
    lfs.enable = true;

    # credential.helper comes from desktop/dev-tools/git-tools.nix; gh is
    # desktop-only because it does not cross-compile for aarch64.
    settings = {
      user = {
        name = "t3u-tsu";
        email = "t3u@t3u.uk";
      };
      core.editor = "vim";
      init.defaultBranch = "main";
      pull.rebase = true;
    };
  };
}
