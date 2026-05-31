{ osConfig, ... }:

{
  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;

    settings = {
      "torii-chan" = {
        HostName = "10.0.0.1";
        User = osConfig.my.user.name;
      };
      "sando-kun" = {
        HostName = "10.0.0.2";
        User = osConfig.my.user.name;
      };
      "kagutsuchi-sama" = {
        HostName = "10.0.0.3";
        User = osConfig.my.user.name;
      };
      "shosoin-tan" = {
        HostName = "10.0.0.4";
        User = osConfig.my.user.name;
      };
      "BrokenPC" = {
        HostName = "10.0.0.100";
        User = osConfig.my.user.name;
      };
      "torii-chan sando-kun kagutsuchi-sama shosoin-tan BrokenPC 10.0.0.*" = {
        IdentityFile = "~/.ssh/id_ed25519";
        ServerAliveInterval = 60;
        SetEnv = {
          TERM = "xterm-256color";
        };
      };
    };
  };
}
