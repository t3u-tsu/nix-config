# nixos/installer/flake.nix - ConoHa VPS 512MB 向けインストーラ ISO の
#                             スタンドアロンビルド用 flake
#
# リポジトリのルート flake.nix を変更せずに、このディレクトリだけで ISO を
# ビルドするためのサブ flake。nixos-generators は NixOS 25.05 以降 nixpkgs に
# 統合され非推奨のため、nixpkgs 標準の image framework（system.build.images）
# を使う。
#
# 使い方:
#   1. （任意）静的 IP を焼き込む: ./wan-ip.nix の ipv4 / gateway を実 IP に変更
#   2. ビルド:
#        nix build path:./nixos/installer#default -o result-iso
#   3. 生成物の確認:
#        ls result-iso/iso/     # nixos-<version>-x86_64-linux.iso
#
# ルート flake.nix へ統合する場合（別タスク）は、このファイルの packages 定義を
# そのまま移植できる:
#   packages.x86_64-linux.torii-chan-iso =
#     self.nixosConfigurations.<cfg>.config.system.build.images.iso-installer;
# 統合後はこのサブ flake は削除してよい。
{
  description = "ConoHa VPS 512MB 用 NixOS インストーラ ISO（スタンドアロン）";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
  };

  outputs =
    {
      self,
      nixpkgs,
      ...
    }:
    let
      system = "x86_64-linux";
      isoConfig = nixpkgs.lib.nixosSystem {
        inherit system;
        # wan-ip.nix は静的 IP の差し込み口（null のままなら手動設定モード）
        modules = [
          ./default.nix
          ./wan-ip.nix
        ];
      };
    in
    {
      nixosConfigurations.conoha-installer-iso = isoConfig;

      packages.${system} = {
        # iso-installer バリアント = nixos-generators の install-iso フォーマット相当。
        # installation-cd-base（インストーラ ISO: nixos-install 等を同梱）を自動付加する。
        default = isoConfig.config.system.build.images.iso-installer;
      };
    };
}
