{
  description = "My NixOS configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, home-manager, disko, sops-nix, ... }@inputs:
    let
      lib = import ./lib {
        inherit nixpkgs inputs home-manager disko sops-nix;
      };
      # クロスコンパイル用のオーバーレイ
      overlays = [
        (final: prev: {
          ubootOrangePiZero3 = prev.buildUBoot {
            version = "2024.01";
            defconfig = "orangepi_zero3_defconfig";
            extraMeta.platforms = [ "aarch64-linux" ];
            BL31 = "${prev.armTrustedFirmwareAllwinnerH616}/bl31.bin";
            filesToInstall = [ "u-boot-sunxi-with-spl.bin" ];
            src = prev.fetchFromGitHub {
              owner = "u-boot";
              repo = "u-boot";
              rev = "v2024.01"; # H618サポートが含まれる新しいバージョンを指定
              sha256 = "sha256-0Da7Czy9cpQ+D5EICc3/QSZhAdCBsmeMvBgykYhAQFw="; # ハッシュは一旦仮置き、エラーが出たら修正
            };
          };
        })
      ];
    in
    {
      nixosConfigurations = {
        # 1. SDカード作成用 (Diskoなし、標準モジュール使用)
        "torii-chan-sd" = lib.mkSystem {
          name = "torii-chan"; # ホスト名は同じ
          system = "x86_64-linux";
          targetSystem = "aarch64-linux";
          extraModules = [
            ./hosts/torii-chan/sd-image-installer.nix
            # U-BootパッケージをOverlay等で提供する必要がある場合はここに追加
            ({ config, pkgs, ... }: {
               nixpkgs.overlays = overlays;
            })
          ];
        };

        # 2. 本番/SSD運用用 (将来的にSSD設定を追加)
        "torii-chan" = lib.mkSystem {
          name = "torii-chan";
          system = "x86_64-linux"; # 実機でリビルドするなら "aarch64-linux" だが、クロスで管理するならこのまま
          targetSystem = "aarch64-linux";
          extraModules = [
             ./hosts/torii-chan/fs-hdd.nix
             ./hosts/torii-chan/production-security.nix
          ];
        };

        # 3. SDカード運用での継続開発用 (HDDなし)
        "torii-chan-sd-live" = lib.mkSystem {
          name = "torii-chan";
          system = "x86_64-linux";
          targetSystem = "aarch64-linux";
          extraModules = [
             ./hosts/torii-chan/fs-sd.nix
             ./hosts/torii-chan/production-security.nix
          ];
        };
      };
    };
}
