{ config, ... }:

{
  nixpkgs.config.cudaCapabilities = [ "8.6" ];

  home-manager.users.${config.my.user.name} = {
    my.services.llama = {
      enable = true;
      modelsDir = "/data/llama/models";
      modelsMax = 1;
      sleepIdleSeconds = 300;
      presets = {
        "G9v3-3B-Q4_K_M" = {
          ngl = 99;
          ncmoe = 0;
        };
        "Qwen3.5-4B-Q4_K_M" = {
          ngl = 99;
          ncmoe = 0;
        };
        "Qwen3.5-9B-Q4_K_M" = {
          ngl = 12;
          ncmoe = 0;
        };
        "Ornith-1.5-9B-Q4_K_M" = {
          ngl = 12;
          ncmoe = 0;
        };
        "gemma-4-E4B-Q4_0" = {
          ngl = 99;
          ncmoe = 99;
        };
        "Ling-3.0-tiny-Q4_K_M" = {
          ngl = 99;
          ncmoe = 99;
        };
        "LFM2.5-8B-A1B-Q4_0" = {
          ngl = 99;
          ncmoe = 99;
        };
        "gemma-4-26B-A4B-it-Q4_0" = {
          ngl = 99;
          ncmoe = 99;
        };
      };
    };
  };
}
