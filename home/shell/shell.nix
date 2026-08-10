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
    oh-my-zsh = {
      enable = true;
      plugins = [
        "git"
        "sudo"
        "direnv"
      ];
      theme = ""; # Starship handles the prompt
    };

    # Fall back to a known terminfo when the current TERM is undefined on the
    # remote host (e.g. `xterm-ghostty` from the ghostty terminal), otherwise
    # SSH shells and the prompt break with "can't find terminal definition".
    initContent = ''
      if [[ -n "$TERM" && "$TERM" != "dumb" ]] \
        && command -v infocmp >/dev/null 2>&1 \
        && ! infocmp "$TERM" >/dev/null 2>&1; then
        export TERM=xterm-256color
      fi
    '';
  };
}
