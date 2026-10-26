{
  config,
  lib,
  pkgs,
  ...
}:

let
  username = config.home.username;

  # OpenStack credentials stay in the agenix mount; the launcher injects them
  # into the MCP server environment instead of baking them into mcp.json.
  conohaMcpWrapper = pkgs.writeYshApplication {
    name = "conoha-vps-mcp-schema-fix";
    runtimeInputs = [ pkgs.nodejs ];
    text = ''
      var credentials = ""
      read --all (&credentials) < ${config.age.secrets.conoha_vps_mcp_credentials.path}
      for line in (credentials.lines()) {
        var entry = line.trim()
        if (len(entry) === 0 or entry.startsWith('#')) { continue }
        if (entry.startsWith('export ')) { setvar entry = entry[len('export '):] }
        var eq = entry.find('=')
        if (eq <= 0) { continue }
        var name = entry[:eq].trim()
        var value = entry[eq + 1:].trim()
        var quote = value[:1]
        if (len(value) >= 2 and (quote === '"' or quote === "'") and value.endsWith(quote)) {
          setvar value = value[1:-1]
        }
        setglobal ENV[name] = value
      }
      exec node ${./conoha-schema-fix.js} @ARGV
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
  config = lib.mkIf config.my.home.desktop.dev-tools.ai-tools.enable {
    home.packages = [
      pkgs.nodejs
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
