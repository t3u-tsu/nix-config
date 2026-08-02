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
  # ai-tools (codewhale) が有効なときだけ MCP 設定を生成する
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

    # ~/.codewhale/mcp.json を SOPS テンプレートから生成する。
    # 認証情報は sops.placeholder 経由で注入されるため、リポジトリに平文は残らない。
    sops.templates."codewhale-mcp.json" = {
      # 直接 ~/.codewhale/mcp.json にレンダリングする。
      # home.file.source 経由だと pure evaluation で絶対パス参照が forbidden になるため。
      path = "/home/${username}/.codewhale/mcp.json";
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
                "PATH": "/home/${username}/.nix-profile/bin:/run/current-system/sw/bin:/usr/bin:/bin",
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

  };
}
