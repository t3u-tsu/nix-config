{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.my.services.llama;
  inherit (lib)
    mkEnableOption
    mkIf
    mkOption
    types
    ;
  llama-cpp = pkgs.llama-cpp.override { useCuda = true; };
  presetsIni = pkgs.writeText "llama-models.ini" (
    lib.concatMapStringsSep "\n" (
      name:
      let
        preset = cfg.presets.${name};
      in
      ''
        [${name}]
        n-gpu-layers = ${toString preset.ngl}
        n-cpu-moe = ${toString preset.ncmoe}
        ctx-size = ${toString preset.ctxSize}
      ''
    ) (builtins.attrNames cfg.presets)
  );
in
{
  options.my.services.llama = {
    enable = mkEnableOption "llama.cpp inference server";

    modelsDir = mkOption {
      type = types.str;
      default = "/var/lib/llama/models";
      description = "Directory containing GGUF model files to serve.";
    };

    modelsMax = mkOption {
      type = types.int;
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

    ngl = mkOption {
      type = types.int;
      default = 99;
      description = "Number of layers to offload to the GPU.";
    };

    ncmoe = mkOption {
      type = types.int;
      default = 99;
      description = "Number of MoE expert layers to keep on the CPU.";
    };

    threads = mkOption {
      type = types.int;
      default = 8;
      description = "CPU thread count.";
    };

    ctxSize = mkOption {
      type = types.int;
      default = 0;
      description = "Prompt context size (0 = loaded from model).";
    };

    presets = mkOption {
      type = types.attrsOf (
        types.submodule {
          options = {
            ngl = mkOption {
              type = types.either types.int types.str;
              default = 99;
              description = "Number of layers to offload to the GPU (int, 'auto', or 'all').";
            };
            ncmoe = mkOption {
              type = types.int;
              default = 99;
              description = "Number of MoE expert layers to keep on the CPU.";
            };
            ctxSize = mkOption {
              type = types.int;
              default = 0;
              description = "Prompt context size (0 = loaded from model).";
            };
          };
        }
      );
      default = { };
      description = "Per-model presets (model name -> settings).";
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
        ExecStart = "${llama-cpp}/bin/llama-server --models-dir ${cfg.modelsDir} --models-max ${toString cfg.modelsMax} ${
          lib.optionalString (cfg.presets != { }) "--models-preset ${presetsIni}"
        } --no-kv-offload -ngl ${toString cfg.ngl} -ncmoe ${toString cfg.ncmoe} -t ${toString cfg.threads} -c ${toString cfg.ctxSize} --host ${cfg.host} --port ${toString cfg.port} --sleep-idle-seconds ${toString cfg.sleepIdleSeconds}";
        Restart = "on-failure";
      };
    };
  };
}
