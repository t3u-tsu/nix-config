{
  inputs,
  config,
  lib,
  ...
}:
let
  deployLib = inputs.deploy-rs.lib;
in
{
  flake.deploy = {
    autoRollback = true;
    magicRollback = true;
    interactiveSudo = true;

    nodes = {
      # Google Cloud on-demand failover node (x86_64-linux, 1GB RAM)
      "torii-chan-gcp" = {
        hostname = "torii-chan-gcp.t3u.uk";
        sshUser = "t3u";
        autoRollback = true;
        profiles.system = {
          user = "root";
          path = deployLib.x86_64-linux.activate.nixos config.flake.nixosConfigurations.torii-chan-gcp;
        };
      };

      # Physical edge gateway SBC (aarch64-linux, 1GB RAM)
      "torii-chan" = {
        hostname = "10.0.0.1";
        sshUser = "t3u";
        autoRollback = true;
        profiles.system = {
          user = "root";
          path = deployLib.aarch64-linux.activate.nixos config.flake.nixosConfigurations.torii-chan-hdd;
        };
      };

      # Explicit torii-chan-hdd alias for SBC storage profile
      "torii-chan-hdd" = {
        hostname = "10.0.0.1";
        sshUser = "t3u";
        autoRollback = true;
        profiles.system = {
          user = "root";
          path = deployLib.aarch64-linux.activate.nixos config.flake.nixosConfigurations.torii-chan-hdd;
        };
      };

      # Main tower server node (x86_64-linux)
      "shosoin-tan" = {
        hostname = "10.0.0.4";
        sshUser = "t3u";
        autoRollback = true;
        profiles.system = {
          user = "root";
          path = deployLib.x86_64-linux.activate.nixos config.flake.nixosConfigurations.shosoin-tan;
        };
      };
    };
  };

  perSystem =
    { system, ... }:
    let
      # deployChecks builds each node's activation package, so a node can only be
      # checked on a builder for its own system. Emit the checks on x86_64-linux
      # only (CI and workstations, like pre-commit.check) and restrict them to the
      # nodes targeting it; otherwise `nix flake check --all-systems` tries to
      # build aarch64 closures on x86_64.
      nodes = lib.filterAttrs (
        _: node: node.profiles.system.path.system == system
      ) config.flake.deploy.nodes;
      deployChecks = lib.optionalAttrs (system == "x86_64-linux" && deployLib ? ${system}) (
        deployLib.${system}.deployChecks (config.flake.deploy // { inherit nodes; })
      );
    in
    {
      checks = deployChecks;
    };
}
