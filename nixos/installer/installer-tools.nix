# nixos/installer/installer-tools.nix - インストール補助ツールの同梱
#
# インストール作業を SSH だけで完結させるための補助スクリプト
# install-nixos（install-nixos.sh）を PATH に追加する。
#
# スクリプトの役割:
#   - install-nixos.sh network ... ネットワークの手動設定（静的 IP が
#     ISO に焼き込まれていない場合のフォールバック）
#   - install-nixos.sh install .... ディスク分割 → フォーマット → swap 作成
#     → nixos-install の一括実行
#
# 注意:
#   - nixos-install / nixos-generate-config / parted / gptfdisk は標準の
#     インストーラ ISO（module-list.nix の installer/tools/tools.nix と
#     profiles/base.nix）に既に含まれるため、ここでは再追加しない。
#   - スクリプトには認証情報・秘密鍵をハードコードしない（公開鍵のみ）。
{
  pkgs,
  ...
}:

{
  config = {
    environment.systemPackages = [
      # インストール自動化スクリプト（install-nixos として PATH に追加）
      (pkgs.writeShellScriptBin "install-nixos" (builtins.readFile ./install-nixos.sh))

      # 手動フォールバックやファイル転送に使うツール
      pkgs.curl
    ];
  };
}
