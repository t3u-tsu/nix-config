{
  config,
  lib,
  pkgs,
  ...
}:

with lib;
let
  username = config.home.username;

  # OpenStack credentials stay in the agenix mount; the launcher sources them
  # into the MCP server environment instead of baking them into mcp.json.
  conohaMcpWrapper = pkgs.writeShellApplication {
    name = "conoha-vps-mcp-schema-fix";
    runtimeInputs = [ pkgs.nodejs ];
    text = ''
      set -a
      # shellcheck source=/dev/null
      . "${config.age.secrets.conoha_vps_mcp_credentials.path}"
      set +a
      exec node ${./conoha-schema-fix.js}
    '';
  };

  mcpConfig = pkgs.writeText "codewhale-mcp.json" ''
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
            "PATH": "/etc/profiles/per-user/${username}/bin:${config.home.homeDirectory}/.nix-profile/bin:/run/current-system/sw/bin:/usr/bin:/bin"
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
in
{
  config = mkIf config.my.home.desktop.dev-tools.ai-tools.enable {
    home.packages = [
      pkgs.nodejs # Required to run conoha-vps-mcp
      conohaMcpWrapper
    ];

    age.secrets.conoha_vps_mcp_credentials = {
      rekeyFile = ../../../../secrets/master/services/conoha-vps-mcp/credentials.env.age;
    };

    home.activation.conohaMcpConfig = config.lib.dag.entryAfter [ "writeBoundary" ] ''
      mkdir -p ${config.home.homeDirectory}/.codewhale
      install -m 600 ${mcpConfig} ${config.home.homeDirectory}/.codewhale/mcp.json
    '';
  };
}
