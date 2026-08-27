{ inputs, ... }:

{
  config = {
    nixpkgs.overlays = [ inputs.llama-cpp.overlays.default ];
    nixpkgs.config.allowUnfree = true;
  };
}
