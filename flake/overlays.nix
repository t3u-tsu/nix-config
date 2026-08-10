{ inputs, lib, ... }:
{
  flake.overlays.default = lib.composeManyExtensions [
    # Minecraft server overlay
    inputs.nix-minecraft.overlay

    # Niri compositor (from niri-flake)
    inputs.niri.overlays.niri

    # Ghostty terminal
    (final: prev: {
      ghostty = inputs.ghostty.packages.${prev.stdenv.hostPlatform.system}.default;
    })

    # PipeWire i686 workaround (disable broken dependencies on 32-bit)
    (final: prev: {
      pkgsi686Linux = prev.pkgsi686Linux // {
        pipewire = prev.pkgsi686Linux.pipewire.override {
          ffadoSupport = false;
          ffado = null;
          libcamera = prev.pkgsi686Linux.libcamera.overrideAttrs (old: {
            meta = (old.meta or { }) // {
              platforms = [ ];
            };
          });
          rocSupport = false;
          roc-toolkit = null;
        };
      };
    })

    # Unstable packages + U-Boot for Orange Pi Zero 3
    (final: prev: {
      unstable = import inputs.nixpkgs-unstable {
        inherit (prev.stdenv.hostPlatform) system;
        config.allowUnfree = true;
      };

      ubootOrangePiZero3 = prev.buildUBoot {
        version = "2024.01";
        defconfig = "orangepi_zero3_defconfig";
        extraMeta.platforms = [ "aarch64-linux" ];
        env.BL31 = "${prev.armTrustedFirmwareAllwinnerH616}/bl31.bin";
        filesToInstall = [ "u-boot-sunxi-with-spl.bin" ];
        src = prev.fetchFromGitHub {
          owner = "u-boot";
          repo = "u-boot";
          rev = "v2024.01";
          sha256 = "sha256-0Da7Czy9cpQ+D5EICc3/QSZhAdCBsmeMvBgykYhAQFw=";
        };
      };
    })
  ];
}
