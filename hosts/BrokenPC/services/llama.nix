_:

{
  my.services.llama = {
    enable = true;
    enableCuda = true;
    modelsDir = "/data/llama/models";
    modelsMax = 1;
    sleepIdleSeconds = 300;
    threads = 12;
    threadsBatch = 16;
    cacheRam = 1024;
    # Omit ngl / ncmoe so llama-server's --fit auto-allocates layers across
    # the 4 GB RTX 3050 Ti alongside the KV-cache and MoE-cache tuning options.
    presets = {
      "G9v3-3B-Q4_K_M" = {
        ctxSize = 32768;
        cacheTypeK = "q8_0";
        cacheTypeV = "q8_0";
        fitTarget = 256;
      };
      "LFM2.5-8B-A1B-Q4_0" = {
        ctxSize = 32768;
        cacheTypeK = "q8_0";
        cacheTypeV = "q8_0";
        fitTarget = 256;
        moeCacheMib = 1024;
        moeCacheCpuShare = 0.0;
      };
      "Ling-3.0-tiny-Q4_K_M" = {
        ctxSize = 32768;
        cacheTypeK = "q8_0";
        cacheTypeV = "q8_0";
        fitTarget = 256;
        moeCacheMib = 1024;
        moeCacheCpuShare = 0.0;
      };
      "Ling-3.0-tiny-Uncensored-Abliterated.Q8_0" = {
        ctxSize = 32768;
        cacheTypeK = "q8_0";
        cacheTypeV = "q8_0";
        fitTarget = 256;
        moeCacheMib = 1024;
        moeCacheCpuShare = 0.0;
      };
      "Qwen3.5-4B-Q4_K_M" = {
        ctxSize = 32768;
        cacheTypeK = "q8_0";
        cacheTypeV = "q8_0";
        fitTarget = 256;
      };
      "Qwen3.5-9B-Q4_K_M" = {
        ctxSize = 32768;
        cacheTypeK = "q8_0";
        cacheTypeV = "q8_0";
        fitTarget = 256;
      };
      "Ornith-1.5-9B-Q4_K_M" = {
        ctxSize = 32768;
        cacheTypeK = "q8_0";
        cacheTypeV = "q8_0";
        fitTarget = 256;
      };
      "LFM2.5-24B-A2B-QAD-Q4_0" = {
        ctxSize = 65536;
        cacheTypeK = "q8_0";
        cacheTypeV = "q8_0";
        fitTarget = 256;
        moeCacheMib = 1024;
        moeCacheCpuShare = 0.0;
      };
      "gemma-4-26B-A4B-it-UD-IQ4_XS" = {
        ctxSize = 65536;
        cacheTypeK = "q8_0";
        cacheTypeV = "q8_0";
        fitTarget = 256;
        moeCacheMib = 512;
        moeCacheCpuShare = 0.0;
      };
      "ELYZA-Thinking-1.0-llm-jp-4-32b-a3b-Q3_K_S" = {
        ctxSize = 16384;
        cacheTypeK = "q8_0";
        cacheTypeV = "q8_0";
        fitTarget = 256;
        moeCacheMib = 1024;
        moeCacheCpuShare = 0.0;
      };
      "ELYZA-Thinking-1.0-llm-jp-4-32b-a3b-IQ4_XS" = {
        ctxSize = 16384;
        cacheTypeK = "q8_0";
        cacheTypeV = "q8_0";
        fitTarget = 256;
        moeCacheMib = 512;
      };
    };
  };
}
