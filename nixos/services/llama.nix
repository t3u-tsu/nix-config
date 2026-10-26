{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:

let
  cfg = config.my.services.llama;
  llama-cpp = pkgs.llama-cpp.override { useCuda = cfg.enableCuda; };

  # Render one INI preset section, omitting unset keys so llama-server's
  # defaults (and the --fit auto memory allocation) stay in effect.
  presetSection =
    name: preset:
    let
      lines = lib.filter (l: l != null) [
        (if preset.ngl != null then "n-gpu-layers = ${toString preset.ngl}" else null)
        (if preset.ncmoe != null then "n-cpu-moe = ${toString preset.ncmoe}" else null)
        (if preset.ctxSize != null then "ctx-size = ${toString preset.ctxSize}" else null)
      ];
    in
    ''
      [${name}]
      ${lib.concatStringsSep "\n" lines}
    '';

  presetsIni = pkgs.writeText "llama-models.ini" (
    lib.concatStringsSep "\n" (lib.mapAttrsToList presetSection cfg.presets)
  );
in
{
  options.my.services.llama = {
    enable = lib.mkEnableOption "llama.cpp inference server";

    enableCuda = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Build llama.cpp with the CUDA backend.";
    };

    modelsDir = lib.mkOption {
      type = lib.types.str;
      default = "/var/lib/llama/models";
      description = "Directory containing GGUF model files to serve.";
    };

    modelsMax = lib.mkOption {
      type = lib.types.ints.unsigned;
      default = 1;
      description = "Maximum number of models to load simultaneously.";
    };

    port = lib.mkOption {
      type = lib.types.port;
      default = 8080;
      description = "HTTP API port.";
    };

    host = lib.mkOption {
      type = lib.types.str;
      default = "127.0.0.1";
      description = "Address to bind.";
    };

    threads = lib.mkOption {
      type = lib.types.nullOr lib.types.ints.positive;
      default = null;
      description = "CPU thread count (null = let llama.cpp pick automatically).";
    };

    presets = lib.mkOption {
      type = lib.types.attrsOf (
        lib.types.submodule {
          options = {
            ngl = lib.mkOption {
              type = lib.types.nullOr (
                lib.types.oneOf [
                  lib.types.ints.unsigned
                  lib.types.str
                ]
              );
              default = null;
              description = "Layers to offload to the GPU, or 'all'. Leave null to let --fit decide automatically.";
            };
            ncmoe = lib.mkOption {
              type = lib.types.nullOr lib.types.ints.unsigned;
              default = null;
              description = "Layers whose MoE experts stay on the CPU. Leave null to let --fit offload MoE automatically.";
            };
            ctxSize = lib.mkOption {
              type = lib.types.nullOr lib.types.ints.unsigned;
              default = null;
              description = "Prompt context size. Leave null to use the model's native context with --fit reduction enabled; set 0 explicitly to forbid context reduction.";
            };
          };
        }
      );
      default = { };
      description = "Per-model presets. Each key must match a GGUF file name in modelsDir without the .gguf extension.";
    };

    sleepIdleSeconds = lib.mkOption {
      type = lib.types.int;
      default = -1;
      description = "Idle seconds before unloading the model (-1 = disabled).";
    };
  };

  config = lib.mkIf cfg.enable {
    nixpkgs.overlays = [
      inputs.llama-cpp.overlays.default
      (_final: prev: {
        llama-cpp = prev.llama-cpp.override {
          cudaPackages = prev.cudaPackages // {
            cccl = prev.cudaPackages.cuda_cccl;
          };
        };
      })
    ];

    systemd.services.llama-server = {
      description = "llama.cpp inference server";
      wantedBy = [ "multi-user.target" ];
      after = [ "network.target" ];
      serviceConfig = {
        User = config.my.user.name;
        ExecStart = lib.escapeShellArgs (
          [
            "${llama-cpp}/bin/llama-server"
            "--models-dir"
            cfg.modelsDir
            "--models-max"
            (toString cfg.modelsMax)
            "--host"
            cfg.host
            "--port"
            (toString cfg.port)
            "--sleep-idle-seconds"
            (toString cfg.sleepIdleSeconds)
          ]
          ++ lib.optionals (cfg.threads != null) [
            "--threads"
            (toString cfg.threads)
          ]
          ++ lib.optionals (cfg.presets != { }) [
            "--models-preset"
            "${presetsIni}"
          ]
        );
        Restart = "on-failure";
      };
    };
  };
}
