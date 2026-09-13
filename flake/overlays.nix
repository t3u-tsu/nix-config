{ inputs, lib, ... }:
{
  flake.overlays.default = lib.composeManyExtensions [
    inputs.nix-minecraft.overlay

    inputs.niri.overlays.niri

    (final: prev: {
      ghostty = inputs.ghostty.packages.${prev.stdenv.hostPlatform.system}.default;
    })

    # ffado / libcamera / roc-toolkit are broken on 32-bit, so disable them there.
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

    inputs.llama-cpp.overlays.default
  ];
}
