{
  config,
  lib,
  pkgs,
  ...
}:

with lib;
let
  cfg = config.my.home.desktop.dev-tools.unity;
in
{
  options.my.home.desktop.dev-tools.unity = {
    enable = mkEnableOption "Unity development tools";
    useDistrobox = mkOption {
      type = types.bool;
      default = true;
      description = ''
        Use Distrobox (Ubuntu 22.04 container) for Unity Hub and Editor
        instead of the native nixpkgs package.

        The native `unityhub` package on NixOS uses bubblewrap for FHS
        emulation, but the Unity Editor build process runs outside that
        sandbox and fails to find system libraries.

        Distrobox provides a full Ubuntu FHS environment where Unity is
        officially supported.
      '';
    };
  };

  config = mkIf cfg.enable (mkMerge [
    # ── Native package path ────────────────────────────────────────
    (mkIf (!cfg.useDistrobox) {
      home.packages = with pkgs; [ unityhub ];
    })

    # ── Distrobox path ─────────────────────────────────────────────
    (mkIf cfg.useDistrobox {
      # Declarative distrobox spec (plain ini, read from sibling file)
      xdg.configFile."distrobox/distrobox.ini".text = builtins.readFile ./distrobox.ini;

      # Desktop entry for host integration
      xdg.desktopEntries.unityhub = {
        name = "Unity Hub";
        genericName = "Unity Hub Launcher";
        exec = "systemd-run --user --collect -- ${config.home.profileDirectory}/bin/unityhub %U";
        icon = "unityhub";
        mimeType = [ "x-scheme-handler/unityhub" ];
        categories = [ "Development" ];
        terminal = false;
      };

      # Self-healing wrapper script
      home.packages = with pkgs; [
        (writeShellScriptBin "unityhub" (
          builtins.replaceStrings
            [
              ''DISTROBOX=$(command -v distrobox || fail "distrobox: command not found")''
              ''PODMAN=$(command -v podman     || fail "podman: command not found")''
            ]
            [
              ''DISTROBOX="${pkgs.distrobox}/bin/distrobox"''
              ''PODMAN="${pkgs.podman}/bin/podman"''
            ]
            (builtins.readFile ./launcher.sh)
        ))
      ];
    })
  ]);
}
