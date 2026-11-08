_:

{
  programs.atuin = {
    enable = true;
    enableZshIntegration = true;
    flags = [ "--disable-up-arrow" ];
    settings = {
      secrets_filter = true;
      history_filter = [
        "^hdel "
        "^hdel$"
        "^pass "
        "^export .*TOKEN.*"
        "^export .*SECRET.*"
        "^export .*KEY.*"
        "^export .*PASSWORD.*"
      ];
    };
  };
}
