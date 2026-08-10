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
  devenv.root = lib.mkIf (builtins.getEnv "PWD" == "") (lib.mkForce "/home/t3u/nix-config");

  env.GREET = "nix-config";

  packages = [
    pkgs.git
    pkgs.nh
    pkgs.nix-tree
    # IaC: declarative management of cloud resources including ConoHa VPS
    # (OpenTofu — MPL-2.0, unfree allowance no longer needed)
    pkgs.opentofu
  ];

  scripts.hello.exec = ''
    echo hello from $GREET
  '';

  enterShell = ''
    echo "Welcome to the nix-config development environment!"
  '';

  enterTest = ''
    echo "Running tests"
    git --version | grep --color=auto "${pkgs.git.version}"
  '';

  git-hooks.hooks = {
    nixfmt.enable = true;
    statix.enable = true;
    # Enforce the Conventional Commits message format (linked to nix-check.yml)
    convco.enable = true;
  };
}
