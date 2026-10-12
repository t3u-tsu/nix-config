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
      };
      "torii-chan-cf" = {
        HostName = "torii-chan-cf-ssh.t3u.uk";
      };
      "sando-kun-cf" = {
        HostName = "sando-kun-cf-ssh.t3u.uk";
      };
      "kagutsuchi-sama-cf" = {
        HostName = "kagutsuchi-sama-cf-ssh.t3u.uk";
      };
      "shosoin-tan-cf" = {
        HostName = "shosoin-tan-cf-ssh.t3u.uk";
      };
      "*-cf-ssh.t3u.uk *-cf" = {
        ProxyCommand = "cloudflared access ssh --hostname %h";
        User = osConfig.my.user.name;
        IdentityFile = "~/.ssh/id_ed25519";
      };
    };
  };
}
