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
  # Only generate the MCP config when ai-tools (codewhale) is enabled
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

    # Generate ~/.codewhale/mcp.json from a SOPS template.
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
                "PATH": "/etc/profiles/per-user/${username}/bin:/home/${username}/.nix-profile/bin:/run/current-system/sw/bin:/usr/bin:/bin",
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
    # Place the sops.templates output (rendered) at ~/.codewhale/mcp.json as a real file.
    home.activation.conohaMcpConfig = config.lib.dag.entryAfter [ "sops-nix" ] ''
      rm -f /home/${username}/.codewhale/mcp.json
      cp -f ${config.sops.templates."codewhale-mcp.json".path} /home/${username}/.codewhale/mcp.json
      chmod 600 /home/${username}/.codewhale/mcp.json
    '';

  };
}
