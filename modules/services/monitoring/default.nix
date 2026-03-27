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
      
      # Open firewall port for local network scraping
      networking.firewall.allowedTCPPorts = [ 9100 ];
    })

    # 2. Central Server configuration (Prometheus & Grafana)
    # Deployed ONLY on the designated monitoring hub (e.g., torii-chan)
    (mkIf (cfg.enable && cfg.isServer) {
      networking.firewall.allowedTCPPorts = [ 3000 9090 ];

      services.prometheus = {
        enable = true;
        port = 9090;
        scrapeConfigs = [
          {
            job_name = "nixos_fleet";
            static_configs = [{
              # The endpoints to scrape metrics from. 
              targets = [ "127.0.0.1:9100" ]; 
            }];
          }
        ];
      };

      # 3. Central Web Dashboard (Grafana)
      services.grafana = {
        enable = true;
        settings = {
          server = {
            http_port = 3000;
            http_addr = "0.0.0.0"; # Bind to all interfaces to allow local network access
          };
        };
      };
    })
  ];
}
