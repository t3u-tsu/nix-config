# Llama.cpp Server (`nixos/services/llama/`)

Local GGUF inference server (`systemd.services.llama-server`) with per-model INI presets and optional CUDA acceleration.

## Modules

| File | Description | Options |
| :--- | :--- | :--- |
| [default.nix](default.nix) | `llama-server` systemd unit; renders per-model INI presets from `presets` and applies the `llama-cpp` flake overlay (CUDA build via `enableCuda`). | `my.services.llama.*` |

## References

- Hybrid GPU topology and inference service usage: [docs/hardware/hybrid-gpu.md](../../../docs/hardware/hybrid-gpu.md)
- Host-specific model presets: [hosts/BrokenPC/services/llama.nix](../../../hosts/BrokenPC/services/llama.nix)
