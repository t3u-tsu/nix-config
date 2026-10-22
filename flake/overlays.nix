{ inputs, lib, ... }:
{
  flake.overlays.default = lib.composeManyExtensions [
    inputs.nix-minecraft.overlay

    inputs.niri.overlays.niri

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

    (
      _final: prev:
      let
        ysh = prev.oils-for-unix.ysh;
        interpreter = lib.getExe ysh;
        check = "${interpreter} -n > /dev/null";
        writeYsh =
          name: argsOrScript:
          if lib.isAttrs argsOrScript && !lib.isDerivation argsOrScript then
            prev.writers.makeScriptWriter (argsOrScript // { inherit interpreter check; }) name
          else
            prev.writers.makeScriptWriter { inherit interpreter check; } name argsOrScript;
        writeYshBin = name: writeYsh "/bin/${name}";
      in
      {
        writers = prev.writers // {
          inherit writeYsh writeYshBin;
        };

        inherit writeYsh writeYshBin;

        writeYshApplication =
          {
            name,
            text,
            runtimeInputs ? [ ],
            checkPhase ? null,
            meta ? { },
            passthru ? { },
            derivationArgs ? { },
          }:
          prev.writeTextFile {
            inherit
              name
              meta
              passthru
              derivationArgs
              ;
            executable = true;
            destination = "/bin/${name}";
            allowSubstitutes = true;
            preferLocalBuild = false;
            text = ''
              #!${interpreter}
            ''
            + lib.optionalString (runtimeInputs != [ ]) ''
              setglobal ENV.PATH = "${lib.makeBinPath runtimeInputs}" ++ (":" ++ get(ENV, 'PATH', "") if (get(ENV, 'PATH', "") !== "") else "")
            ''
            + text;
            checkPhase = if checkPhase == null then "${interpreter} -n \"$target\" > /dev/null" else checkPhase;
          };
      }
    )
  ];
}
