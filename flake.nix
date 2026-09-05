{
  description = "My NixOS configuration fleet";

  inputs = {
    # === Framework ===
    flake-parts.url = "github:hercules-ci/flake-parts";

    # === Nixpkgs ===
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";

    # === System Modules ===
    home-manager = {
      url = "github:nix-community/home-manager/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-index-database = {
      url = "github:nix-community/nix-index-database";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    microvm = {
      url = "github:astro/microvm.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixos-hardware = {
      url = "github:NixOS/nixos-hardware";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # === Shell ===
    pure = {
      url = "github:sindresorhus/pure";
      flake = false;
    };

    # === Desktop Environment ===
    # niri / noctalia / noctalia-greeter / ghostty: no follows to keep the
    # upstream Cachix binary cache hash-matching.
    niri.url = "github:sodiboo/niri-flake";
    # Official Niri compositor package source (via overlays.default).
    niri-wm.url = "github:niri-wm/niri";
    noctalia.url = "github:noctalia-dev/noctalia/cachix";
    noctalia-greeter.url = "github:noctalia-dev/noctalia-greeter";
    ghostty.url = "github:ghostty-org/ghostty";
    zen-browser = {
      url = "github:0xc000022070/zen-browser-flake";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };
    aagl = {
      url = "github:ezKEa/aagl-gtk-on-nix/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    spicetify-nix = {
      url = "github:Gerg-L/spicetify-nix";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };
    # Comfy Spicetify theme (Comfy/color.ini overwritten by Noctalia).
    comfy-theme = {
      url = "github:Comfy-Themes/Spicetify";
      flake = false;
    };

    # === Services ===
    nix-minecraft = {
      url = "github:Infinidoge/nix-minecraft";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    minecraft-discord-bridge = {
      url = "github:t3u-tsu/minecraft-discord-bridge";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    llama-cpp = {
      url = "github:ggml-org/llama.cpp";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.flake-parts.follows = "flake-parts";
    };

    # === Developer Tools ===
    codewhale = {
      url = "github:Hmbown/CodeWhale";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };
    unity-via-distrobox = {
      url = "github:t3u-tsu/unity-via-distrobox-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # === Development Environment ===
    git-hooks = {
      url = "github:cachix/git-hooks.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # === Package Sources ===
    # Chaotic-Nyx, imported by the desktop profile's nyx-overlay module.
    chaotic = {
      url = "github:chaotic-cx/nyx/nyxpkgs-unstable";
    };
  };

  outputs =
    { flake-parts, ... }@inputs:
    flake-parts.lib.mkFlake { inherit inputs; } (
      { ... }:
      {
        imports = [
          ./flake/lib.nix
          ./flake/overlays.nix
          ./flake/hosts.nix
          ./flake/packages.nix
          ./flake/dev.nix
        ];

        systems = [
          "x86_64-linux"
          "aarch64-linux"
        ];
      }
    );
}
