{
  config,
  lib,
  pkgs,
  ...
}:

with lib;
let
  username = config.home.username;
in
{
  config = mkIf config.my.home.desktop.dev-tools.ai-tools.enable {
    sops.secrets = {
      conoha_vps_mcp_tenant_id = {
        sopsFile = ../../../secrets/services/conoha-vps-mcp.yaml;
        key = "OPENSTACK_TENANT_ID";
      };
      conoha_vps_mcp_user_id = {
        sopsFile = ../../../secrets/services/conoha-vps-mcp.yaml;
        key = "OPENSTACK_USER_ID";
      };
      conoha_vps_mcp_password = {
        sopsFile = ../../../secrets/services/conoha-vps-mcp.yaml;
        key = "OPENSTACK_PASSWORD";
      };
    };

    sops.templates."codewhale-mcp.json" = {
      content = ''
        {
          "timeouts": {
            "connect_timeout": 10,
            "execute_timeout": 60,
            "read_timeout": 120
          },
          "servers": {
            "conoha-vps-mcp": {
              "command": "conoha-vps-mcp-schema-fix",
              "args": [],
              "env": {
                "PATH": "/etc/profiles/per-user/${username}/bin:${config.home.homeDirectory}/.nix-profile/bin:/run/current-system/sw/bin:/usr/bin:/bin",
                "OPENSTACK_TENANT_ID": "${config.sops.placeholder.conoha_vps_mcp_tenant_id}",
                "OPENSTACK_USER_ID": "${config.sops.placeholder.conoha_vps_mcp_user_id}",
                "OPENSTACK_PASSWORD": "${config.sops.placeholder.conoha_vps_mcp_password}"
              },
              "disabled": false,
              "enabled": true,
              "required": false,
              "enabled_tools": [],
              "disabled_tools": []
            }
          }
        }
      '';
    };
    # sops.templates renders into the Nix store; codewhale needs a real file at
    # ~/.codewhale/mcp.json, so copy it once sops-nix has run.
    home.activation.conohaMcpConfig = config.lib.dag.entryAfter [ "sops-nix" ] ''
      rm -f ${config.home.homeDirectory}/.codewhale/mcp.json
      cp -f ${
        config.sops.templates."codewhale-mcp.json".path
      } ${config.home.homeDirectory}/.codewhale/mcp.json
      chmod 600 ${config.home.homeDirectory}/.codewhale/mcp.json
    '';

  };
}
