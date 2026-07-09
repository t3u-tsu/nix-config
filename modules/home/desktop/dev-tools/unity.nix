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
        officially supported. After enabling this option and rebuilding:

          1. Create the container:
             distrobox create --image docker.io/library/ubuntu:22.04 --name unity --init

          2. Enter and install Unity Hub:
             distrobox enter unity
             # Follow Unity's official Linux install guide inside the container

          3. Export the app to the host:
             distrobox enter unity -- distrobox-export --app unityhub

        Set `useDistrobox = false` to fall back to the native `unityhub` package.
      '';
    };
  };

  config = mkIf cfg.enable (mkMerge [
    # When useDistrobox is true: do NOT install unityhub natively.
    # The user is expected to install it inside the distrobox container.
    (mkIf (!cfg.useDistrobox) {
      home.packages = with pkgs; [
        unityhub
      ];
    })

    # When useDistrobox is true: provide a convenience wrapper script
    # that reminds the user to set up the container if it's missing.
    (mkIf cfg.useDistrobox {
      home.packages = with pkgs; [
        # Convenience launcher: `unityhub` command that auto-enters the container
        (writeShellScriptBin "unityhub" ''
          if distrobox list 2>/dev/null | grep -q '^unity '; then
            exec distrobox enter unity -- unityhub "$@"
          else
            echo "Unity distrobox container not found."
            echo ""
            echo "Create it first:"
            echo "  distrobox create --image docker.io/library/ubuntu:22.04 --name unity --init"
            echo ""
            echo "Then enter and install Unity Hub:"
            echo "  distrobox enter unity"
            echo "  # Follow: https://docs.unity.com/en-us/hub/install-hub-linux"
            exit 1
          fi
        '')
      ];
    })
  ]);
}
