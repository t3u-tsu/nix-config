# Llama.cpp Server (`nixos/services/llama/`)

Local GGUF inference server (`systemd.services.llama-server`) with per-model preset sections in a single INI and optional CUDA acceleration.

## Modules

| File | Description | Options / Notes |
| :--- | :--- | :--- |
| [default.nix](default.nix) | `llama-server` systemd unit; renders per-model preset sections from `presets` (unset keys omitted so `--fit` decides) and enables the `llama-cpp` flake overlay, building the package with `useCuda = cfg.enableCuda`. | `my.services.llama.*` |

## References

- Hybrid GPU topology and inference service usage: [docs/hardware/hybrid-gpu.md](../../../docs/hardware/hybrid-gpu.md)
- Host-specific model presets: [hosts/BrokenPC/services/llama.nix](../../../hosts/BrokenPC/services/llama.nix)
