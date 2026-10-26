{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.my.home.desktop.dev-tools.ai-tools;
  sources = pkgs.callPackage ../../../../_sources/generated.nix { };
in
{
  config = lib.mkIf cfg.enable {
    home.file.".agents/skills/hush".source = "${sources.hush.src}/skills/hush";

    home.file.".agents/skills/ysh".source = ./skills/ysh;
  };
}
