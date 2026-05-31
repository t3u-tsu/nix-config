{
  config,
  pkgs,
  ...
}:

{
  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;
    history = {
      size = 10000;
      path = "$HOME/.zsh_history";
    };
    initContent = ''
      # Fallback TERM if xterm-ghostty is not supported on this host
      if [ "$TERM" = "xterm-ghostty" ] && ! infocmp "$TERM" >/dev/null 2>&1; then
        export TERM=xterm-256color
      fi
    '';

    oh-my-zsh = {
      enable = true;
      plugins = [
        "git"
        "sudo"
        "docker"
        "direnv"
      ];
      theme = ""; # Starship handles the prompt
    };
  };
}
