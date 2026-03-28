{ config, lib, pkgs, ... }:

with lib;
let
  cfg = config.my.services.monitoring;
in {
  options.my.services.monitoring = {
    enable = mkEnableOption "Enable Prometheus Node Exporter agent";
    isServer = mkEnableOption "Enable central Prometheus and Grafana dashboard server";
  };

  config = mkMerge [
    # 1. Agent configuration (node_exporter)
    # Deployed on all machines with `my.services.monitoring.enable = true`
    (mkIf cfg.enable {
      services.prometheus.exporters.node = {
        enable = true;
        port = 9100;
        enabledCollectors = [ "systemd" ];
      };
      
      # Open firewall port for local network scraping only on WireGuard
      networking.firewall.interfaces.wg0.allowedTCPPorts = [ 9100 ];
    })

    # 2. Central Server configuration (Prometheus & Grafana)
    # Deployed ONLY on the designated monitoring hub (e.g., torii-chan)
    (mkIf (cfg.enable && cfg.isServer) {
      # Restricted access via WireGuard Management Interface
      networking.firewall.interfaces.wg0.allowedTCPPorts = [ 3000 9090 ];

      sops.secrets.grafana_admin_password = {
        owner = "grafana";
      };

      services.prometheus = {
        enable = true;
        port = 9090;
        scrapeConfigs = [
          {
            job_name = "nixos_fleet";
            static_configs = [{
              # Fleet-wide targets via WireGuard Management Network
              targets = [ 
                "10.0.0.1:9100"   # torii-chan
                "10.0.0.2:9100"   # sando-kun
                "10.0.0.3:9100"   # kagutsuchi-sama
                "10.0.0.4:9100"   # shosoin-tan
                "10.0.0.100:9100" # BrokenPC (Management)
              ]; 
            }];
          }
        ];
      };

      # 3. Central Web Dashboard (Grafana)
      services.grafana = {
        enable = true;
        settings = {
          security = {
            admin_password = "$__file{${config.sops.secrets.grafana_admin_password.path}}";
          };
          server = {
            http_port = 3000;
            http_addr = "0.0.0.0"; # Bind to all interfaces but controlled by firewall
          };
        };
      };
    })
  ];
}
