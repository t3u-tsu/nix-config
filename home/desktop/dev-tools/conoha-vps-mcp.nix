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
      # デフォルトの rendered パスに生成し、activation で ~/.codewhale/mcp.json に実ファイルとしてコピーする。
      # 理由: sops.templates の path に直接指定するとシンボリックリンクになり、
      #       codewhale が MCP config path must be a regular file で拒否するため。
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
    # sops.templates の出力（rendered）を実ファイルとして ~/.codewhale/mcp.json に配置する。
    # sops のレンダリング（setupSecrets）後に実行する。
    home.activation.conohaMcpConfig = config.lib.dag.entryAfter [ "setupSecrets" ] ''
      rm -f /home/${username}/.codewhale/mcp.json
      cp -f ${config.sops.templates."codewhale-mcp.json".path} /home/${username}/.codewhale/mcp.json
      chmod 600 /home/${username}/.codewhale/mcp.json
    '';

  };
}
