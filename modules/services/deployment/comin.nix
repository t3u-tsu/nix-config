{ config, pkgs, lib, ... }:

with lib;
let
  cfg = config.my.services.deployment.comin;
in {
  options.my.services.deployment.comin = {
    enable = mkEnableOption "comin deployment service";
    repo = mkOption {
      type = types.str;
      default = "https://github.com/t3u-tsu/nix-config.git";
      description = "The git repository to pull from.";
    };
    branch = mkOption {
      type = types.str;
      default = "main";
      description = "The branch to follow.";
    };
  };

  config = mkIf cfg.enable {
    # comin pulls and deploys automatically
    services.comin = {
      enable = true;
      remotes = [
        {
          name = "origin";
          url = cfg.repo;
          poller.period = 300; # Poll every 5 minutes
          branches.main.name = cfg.branch;
        }
      ];
    };
  };
}
