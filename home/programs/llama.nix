{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.my.services.llama;
  inherit (lib)
    attrNames
    concatStringsSep
    filter
    mapAttrsToList
    mkEnableOption
    mkIf
    mkOption
    optional
    types
    ;
  llama-cpp = pkgs.llama-cpp.override { useCuda = cfg.enableCuda; };

  # Render one INI preset section, omitting unset keys so llama-server's
  # defaults (and the --fit auto memory allocation) stay in effect.
  presetSection =
    name: preset:
    let
      lines = filter (l: l != null) [
        (if preset.ngl != null then "n-gpu-layers = ${toString preset.ngl}" else null)
        (if preset.ncmoe != null then "n-cpu-moe = ${toString preset.ncmoe}" else null)
        (if preset.ctxSize != null then "ctx-size = ${toString preset.ctxSize}" else null)
      ];
    in
    ''
      [${name}]
      ${concatStringsSep "\n" lines}
    '';

  presetsIni = pkgs.writeText "llama-models.ini" (
    concatStringsSep "\n" (mapAttrsToList presetSection cfg.presets)
  );
in
{
  options.my.services.llama = {
    enable = mkEnableOption "llama.cpp inference server";

    enableCuda = mkOption {
      type = types.bool;
      default = false;
      description = "Build llama.cpp with the CUDA backend.";
    };

    modelsDir = mkOption {
      type = types.str;
      default = "/var/lib/llama/models";
      description = "Directory containing GGUF model files to serve.";
    };

    modelsMax = mkOption {
      type = types.ints.unsigned;
      default = 1;
      description = "Maximum number of models to load simultaneously.";
    };

    port = mkOption {
      type = types.port;
      default = 8080;
      description = "HTTP API port.";
    };

    host = mkOption {
      type = types.str;
      default = "127.0.0.1";
      description = "Address to bind.";
    };

    threads = mkOption {
      type = types.nullOr types.ints.positive;
      default = null;
      description = "CPU thread count (null = let llama.cpp pick automatically).";
    };

    presets = mkOption {
      type = types.attrsOf (
        types.submodule {
          options = {
            ngl = mkOption {
              type = types.nullOr (
                types.oneOf [
                  types.ints.unsigned
                  types.str
                ]
              );
              default = null;
              description = "Layers to offload to the GPU, or 'all'. Leave null to let --fit decide automatically.";
            };
            ncmoe = mkOption {
              type = types.nullOr types.ints.unsigned;
              default = null;
              description = "Layers whose MoE experts stay on the CPU. Leave null to let --fit offload MoE automatically.";
            };
            ctxSize = mkOption {
              type = types.nullOr types.ints.unsigned;
              default = null;
              description = "Prompt context size. Leave null to use the model's native context with --fit reduction enabled; set 0 explicitly to forbid context reduction.";
            };
          };
        }
      );
      default = { };
      description = "Per-model presets. Each key must match a GGUF file name in modelsDir without the .gguf extension.";
    };

    sleepIdleSeconds = mkOption {
      type = types.int;
      default = -1;
      description = "Idle seconds before unloading the model (-1 = disabled).";
    };
  };

  config = mkIf cfg.enable {
    systemd.user.services.llama-server = {
      Unit = {
        Description = "llama.cpp inference server";
      };
      Install = {
        WantedBy = [ "default.target" ];
      };
      Service = {
        ExecStart = concatStringsSep " " (
          [
            "${llama-cpp}/bin/llama-server"
            "--models-dir ${cfg.modelsDir}"
            "--models-max ${toString cfg.modelsMax}"
            "--host ${cfg.host}"
            "--port ${toString cfg.port}"
            "--sleep-idle-seconds ${toString cfg.sleepIdleSeconds}"
          ]
          ++ optional (cfg.threads != null) "--threads ${toString cfg.threads}"
          ++ optional (cfg.presets != { }) "--models-preset ${presetsIni}"
        );
        Restart = "on-failure";
      };
    };
  };
}
