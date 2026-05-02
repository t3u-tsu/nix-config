{
  config,
  lib,
  pkgs,
  ...
}:

with lib;
let
  cfg = config.my.home.desktop.dev-tools.vscode;
in
{
  options.my.home.desktop.dev-tools.vscode = {
    enable = mkEnableOption "Visual Studio Code editor";
  };

  config = mkIf cfg.enable {
    programs.vscode = {
      enable = true;
      package = pkgs.vscode;
      profiles.default.extensions = with pkgs.vscode-extensions; [
        jnoortheen.nix-ide
        ms-ceintl.vscode-language-pack-ja
      ];
    };
  };
}
