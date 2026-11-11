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
    {
      system,
      pkgs,
      ...
    }:
    let
      deployChecks = lib.optionalAttrs (deployLib ? ${system}) (
        deployLib.${system}.deployChecks config.flake.deploy
      );
    in
    {
      checks =
        deployChecks
        // lib.optionalAttrs (deployLib ? ${system}) {
          deploy-check = pkgs.linkFarm "deploy-check" (
            lib.mapAttrsToList (name: path: { inherit name path; }) deployChecks
          );
        };
    };
}
