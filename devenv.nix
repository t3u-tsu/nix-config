{
  pkgs,
  lib,
  config,
  inputs,
  ...
}:
{
  # devenv.root を明示して pure 評価（--impure なし）でも動作させる。
  # ※ 絶対パスのため、リポジトリのクローン先を変える場合は更新が必要。
  devenv.root = "/home/t3u/nix-config";

  # terraform は BUSL-1.1（nixpkgs では unfree 扱い）。allowUnfree 済みの
  # nixpkgs インスタンスから取得して、devenv の pkgs で使えるようにする。
  overlays = [
    (final: prev: {
      # allowUnfree 済みの nixpkgs から terraform を取得（inherit で同名アサインを回避）
      inherit
        (
          (import inputs.nixpkgs {
            inherit (final.stdenv.hostPlatform) system;
            config.allowUnfree = true;
          })
        )
        terraform
        ;
    })
  ];

  # https://devenv.sh/basics/
  env.GREET = "nix-config";

  # https://devenv.sh/packages/
  packages = [
    pkgs.git
    pkgs.nh
    pkgs.nix-tree
    # Infrastructure as Code: ConoHa VPS を含むクラウドリソースの宣言的管理
    pkgs.terraform
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
