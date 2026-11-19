{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.my.home.desktop.ssh-signing;

  allowedSigners = pkgs.writeText "ssh-allowed-signers" "${config.programs.git.settings.user.email} ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAII4OoSQDaRFJnrYJDcWFyArqHqSs9ma4bjC5OYQV6NN8 git-signing\n";
in
{
  options.my.home.desktop.ssh-signing = {
    enable = lib.mkEnableOption "SSH commit signing with an agenix-managed key";
  };

  config = lib.mkIf cfg.enable {
    age.secrets.ssh_signing_key = {
      rekeyFile = ../../secrets/master/services/signing/ssh_signing_key.age;
      path = "${config.home.homeDirectory}/.ssh/id_ed25519_signing";
    };

    programs.git.settings = {
      gpg.format = "ssh";
      commit.gpgsign = true;
      user.signingkey = config.age.secrets.ssh_signing_key.path;
      gpg.ssh.allowedSignersFile = "${allowedSigners}";
    };
  };
}
