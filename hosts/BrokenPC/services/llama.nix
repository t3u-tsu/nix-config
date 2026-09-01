{ config, ... }:

{
  home-manager.users.${config.my.user.name} = {
    my.services.llama = {
      enable = true;
      enableCuda = true;
      modelsDir = "/data/llama/models";
      modelsMax = 1;
      sleepIdleSeconds = 300;
      # Presets keep explicit values where the user tuned them (3B/4B/9B).
      # The Ling-3.0-tiny entries are intentionally empty: unset keys are
      # omitted from the INI so llama-server's --fit auto-allocation picks
      # ngl / ctx / ncmoe for the 4GB RTX 3050 Ti. Setting ngl or ncmoe
      # explicitly would disable fit's automatic MoE offload.
      presets = {
        "G9v3-3B-Q4_K_M" = {
          ngl = 99;
          ncmoe = 0;
          ctxSize = 32768;
        };
        "Qwen3.5-4B-Q4_K_M" = {
          ngl = 99;
          ncmoe = 0;
          ctxSize = 16384;
        };
        "Qwen3.5-9B-Q4_K_M" = {
          ngl = 12;
          ncmoe = 0;
          ctxSize = 32768;
        };
        "Ornith-1.5-9B-Q4_K_M" = {
          ngl = 12;
          ncmoe = 0;
          ctxSize = 32768;
        };
        "Ling-3.0-tiny-Q4_K_M" = { };
        "Ling-3.0-tiny-Uncensored-Abliterated.Q8_0" = { };
        "LFM2.5-8B-A1B-Q4_0" = { };
      };
    };
  };
}
