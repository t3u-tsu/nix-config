{ config, pkgs, ... }:

{
  programs.git = {
    enable = true;
    
    # New Home Manager 24.11+ syntax for Git
    settings = {
      user.name = "t3u-tsu";
      user.email = "t3u@t3u.uk";
      core.editor = "vim";
      init.defaultBranch = "main";
      
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
    pinentry.package = pkgs.pinentry-qt; # Corrected syntax
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
