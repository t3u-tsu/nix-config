{ config, pkgs, ... }:

{
  services.minecraft-servers.servers.lobby = {
    enable = true;
    package = pkgs.paperServers.paper; # 常にその時点の最新安定版を指す属性

    jvmOpts = "-Xms2G -Xmx4G";

    serverProperties = {
      server-port = 25566;
      online-mode = false; # Velocity が認証を行うため false
      white-list = false;
    };

    symlinks = {
      "plugins/ViaVersion.jar" = pkgs.fetchurl {
        url = "https://github.com/ViaVersion/ViaVersion/releases/download/5.2.1/ViaVersion-5.2.1.jar";
        sha256 = "sha256-Kx83C9gb5gVd0ebM5GkmvYUrI15kSNZr2myV+6yWKsM=";
      };
      "plugins/ViaBackwards.jar" = pkgs.fetchurl {
        url = "https://github.com/ViaVersion/ViaBackwards/releases/download/5.2.1/ViaBackwards-5.2.1.jar";
        sha256 = "sha256-2wbj6CvMu8hnL260XLf8hqhr6GG/wxh+SU8uX5+x8NY=";
      };
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
