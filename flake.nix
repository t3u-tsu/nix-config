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

    # === Desktop Environment ===
    niri = {
      url = "github:sodiboo/niri-flake";
    };
    noctalia = {
      url = "github:noctalia-dev/noctalia/cachix";
    };
    noctalia-greeter = {
      url = "github:noctalia-dev/noctalia-greeter";
    };
    ghostty = {
      url = "github:ghostty-org/ghostty";
    };
    zen-browser = {
      url = "github:0xc000022070/zen-browser-flake";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };
    awww = {
      url = "git+https://codeberg.org/LGFae/awww";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };
    spicetify-nix = {
      url = "github:Gerg-L/spicetify-nix";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };
    antigravity-nix = {
      url = "github:jacopone/antigravity-nix";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
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

    # === Developer Tools ===
    codewhale = {
      url = "github:Hmbown/CodeWhale";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };

    # === Development Environment (devenv) ===
    devenv = {
      url = "github:cachix/devenv";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    devenv-root = {
      url = "file+file:///dev/null";
      flake = false;
    };
    nix2container = {
      url = "github:nlewo/nix2container";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    mk-shell-bin = {
      url = "github:rrbutani/nix-mk-shell-bin";
    };
    git-hooks = {
      url = "github:cachix/git-hooks.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # === Package Sources ===
    chaotic = {
      url = "github:chaotic-cx/nyx/nyxpkgs-unstable";
    };
  };

  outputs =
    { flake-parts, devenv, ... }@inputs:
    flake-parts.lib.mkFlake { inherit inputs; } (
      top@{
        config,
        lib,
        inputs,
        ...
      }:
      {
        imports = [
          devenv.flakeModule
          ./flake/overlays.nix
          ./flake/hosts.nix
        ];

        systems = [
          "x86_64-linux"
          "aarch64-linux"
        ];

        perSystem =
          {
            pkgs,
            system,
            ...
          }:
          {
            formatter = pkgs.nixfmt;

            # torii-chan のフェイルオーバー VPS 用インストーラ ISO（旧 nixos/installer サブフレーク）
            # ビルド: nix build .#torii-chan-vps-iso
            # ConoHa VPS は x86_64 のため、ISO は x86_64-linux でのみ公開する。
            # nixosConfigurations には登録しない（nix flake check が ISO を通常の
            # ブート可能システムとして検証し、fileSystems / grub のアサーションで
            # 失敗するため。ISO は packages としてのみ公開する）。
            packages = lib.optionalAttrs (system == "x86_64-linux") {
              torii-chan-vps-iso =
                let
                  mkLib = import ./lib {
                    inherit (inputs)
                      nixpkgs
                      home-manager
                      sops-nix
                      nix-minecraft
                      ;
                    inherit inputs;
                    overlays = lib.attrValues (config.flake.overlays or { });
                  };
                in
                (mkLib.mkSystem {
                  name = "torii-chan";
                  username = "t3u";
                  system = "x86_64-linux";
                  extraModules = [ ./hosts/torii-chan/vps-installer.nix ];
                }).config.system.build.images.iso-installer;
            };

            # devenv の開発環境（devenv.nix をモジュールとして読み込む）
            devenv.shells.default = {
              imports = [ ./devenv.nix ];
            };
          };
      }
    );
}
