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
    home.file = {
      ".agents/skills/hush".source = "${sources.hush.src}/skills/hush";
      ".agents/skills/dispatching-parallel-agents".source =
        "${sources.superpowers.src}/skills/dispatching-parallel-agents";
      ".agents/skills/ysh".source = ./skills/ysh;
      ".gemini/config/skills.json".text = builtins.toJSON {
        entries = [
          { path = "${config.home.homeDirectory}/.agents/skills"; }
        ];
      };
    };
  };
}
