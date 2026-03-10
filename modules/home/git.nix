{ config, pkgs, ... }:

{
  programs.git = {
    enable = true;
    # Global User Identity
    userName = "t3u-tsu";
    userEmail = "t3u@t3u.uk";

    settings = {
      core.editor = "vim";
      init.defaultBranch = "main";
    };

    extraConfig = {
      # Commit Signing with GPG
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
    pinentryPackage = pkgs.pinentry-qt; # Suitable for Wayland/Niri
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
}
