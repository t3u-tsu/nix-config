{ config, pkgs, ... }:

{
  services.minecraft-servers.servers.lobby = {
    enable = true;
    package = pkgs.papermcServers.papermc-1_21_1; # バージョン指定

    jvmOpts = "-Xms2G -Xmx4G";

    serverProperties = {
      server-port = 25566;
      online-mode = false; # Velocity が認証を行うため false
      white-list = false;
    };

    files = {
      "config/paper-global.yml".value = {
        proxies = {
          velocity = {
            enabled = true;
            online-mode = true;
            secret = "@SECRET@"; # 後で置換されるか、直接指定
          };
        };
      };
    };

    # paper-global.yml の secret 部分を symlink または設定で解決する
    # nix-minecraft のモジュールによっては直接 secretFile を指定できる場合がある
    # ここでは単純化のため、ファイルを直接配置する仕組みを検討
  };
}
