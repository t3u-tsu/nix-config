{
  pkgs,
  lib,
  config,
  inputs,
  ...
}:
{
  # devenv.root は devenv CLI（impure）が PWD から自動設定する。
  # 純粋評価（nix flake check --all-systems など）では PWD を参照できないため、
  # PWD が空のときだけフォールバックを設定する（mkForce で devenv 側の空定義を上書き）。
  # ※ CI ではチェックアウト先のパスが devenv 側の PWD で自動設定されるため競合しない。
  devenv.root = lib.mkIf (builtins.getEnv "PWD" == "") (lib.mkForce "/home/t3u/nix-config");

  # https://devenv.sh/basics/
  env.GREET = "nix-config";

  # https://devenv.sh/packages/
  packages = [
    pkgs.git
    pkgs.nh
    pkgs.nix-tree
    # Infrastructure as Code: ConoHa VPS を含むクラウドリソースの宣言的管理
    # (OpenTofu — MPL-2.0, unfree allowance no longer needed)
    pkgs.opentofu
  ];

  # https://devenv.sh/languages/
  # languages.rust.enable = true;

  # https://devenv.sh/processes/
  # processes.dev.exec = "${lib.getExe pkgs.watchexec} -n -- ls -la";

  # https://devenv.sh/services/
  # services.postgres.enable = true;

  # https://devenv.sh/scripts/
  scripts.hello.exec = ''
    echo hello from $GREET
  '';

  # https://devenv.sh/basics/
  enterShell = ''
    echo "Welcome to the nix-config development environment!"
  '';

  # https://devenv.sh/basics/
  # tasks = {
  #   "myproj:setup".exec = "mytool build";
  #   "devenv:enterShell".after = [ "myproj:setup" ];
  # };

  # https://devenv.sh/tests/
  enterTest = ''
    echo "Running tests"
    git --version | grep --color=auto "${pkgs.git.version}"
  '';

  # https://devenv.sh/git-hooks/
  git-hooks.hooks = {
    nixfmt.enable = true;
    statix.enable = true;

    # Conventional Commits メッセージ形式を強制（nix-check.yml のブランチ規約と連動）
    convco.enable = true;
  };

  # See full reference at https://devenv.sh/reference/options/
}
