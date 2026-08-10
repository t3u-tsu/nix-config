{
  pkgs,
  lib,
  config,
  inputs,
  ...
}:
{
  # devenv.root is set automatically by the devenv CLI (impure) from PWD.
  # Pure evaluation (nix flake check --all-systems etc.) cannot reference PWD, so
  # set the fallback only when PWD is empty (mkForce overrides devenv's empty definition).
  # Note: in CI the checkout path is set automatically via devenv's PWD, so there is no conflict.
  devenv.root = lib.mkIf (builtins.getEnv "PWD" == "") (lib.mkForce "/home/t3u/nix-config");

  # https://devenv.sh/basics/
  env.GREET = "nix-config";

  # https://devenv.sh/packages/
  packages = [
    pkgs.git
    pkgs.nh
    pkgs.nix-tree
    # Infrastructure as Code: declarative management of cloud resources including ConoHa VPS
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

    # Enforce the Conventional Commits message format (linked to the branch convention in nix-check.yml)
    convco.enable = true;
  };

  # See full reference at https://devenv.sh/reference/options/
}
