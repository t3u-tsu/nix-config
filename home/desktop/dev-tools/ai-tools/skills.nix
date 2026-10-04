{
  config,
  lib,
  pkgs,
  ...
}:

with lib;
let
  cfg = config.my.home.desktop.dev-tools.ai-tools;
  sources = pkgs.callPackage ../../../../_sources/generated.nix { };
in
{
  config = mkIf cfg.enable {
    # External skills managed via nvfetcher
    home.file.".agents/skills/hush".source = "${sources.hush.src}/skills/hush";

    # Custom skills maintained in this repository
    home.file.".agents/skills/ysh".source = ./skills/ysh;
  };
}
