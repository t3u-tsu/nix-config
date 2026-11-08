{ config, ... }:

{
  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestion = {
      enable = true;
      strategy = [
        "history"
        "completion"
      ];
    };
    syntaxHighlighting = {
      enable = true;
      highlighters = [
        "main"
        "brackets"
      ];
    };
    history = {
      size = 10000;
      save = 10000;
      path = "${config.xdg.dataHome}/zsh/zsh_history";
      extended = true;
      ignoreAllDups = true;
      ignoreSpace = true;
      share = true;
      ignorePatterns = [
        "hdel *"
        "hdel"
      ];
    };
    dotDir = "${config.xdg.configHome}/zsh";
    oh-my-zsh = {
      enable = true;
      plugins = [
        "git"
        "sudo"
      ];
      theme = "";
      extraConfig = ''
        export ZSH_COMPDUMP="${config.xdg.cacheHome}/zsh/zcompdump-''${SHORT_HOST:-$HOST}-''${ZSH_VERSION}"
        mkdir -p "$(dirname "$ZSH_COMPDUMP")"
      '';
    };

    initContent = ''
      # Delete entries from both atuin and zsh history
      hdel() {
        local histfile="${config.xdg.dataHome}/zsh/zsh_history"
        [[ -f "$histfile" ]] || histfile="''${HISTFILE:-$HOME/.zsh_history}"

        local -a targets
        if [[ $# -gt 0 ]]; then
          targets=("$@")
        else
          if ! command -v fzf >/dev/null 2>&1; then
            echo "Usage: hdel <pattern>"
            return 1
          fi
          local selected
          if command -v atuin >/dev/null 2>&1; then
            selected=$(atuin search --cmd-only 2>/dev/null | fzf --multi --reverse --header="Select history entries to delete (Tab: multi-select, Enter: confirm)")
          else
            selected=$(fc -l -n 1 2>/dev/null | fzf --multi --reverse --header="Select history entries to delete (Tab: multi-select, Enter: confirm)")
          fi
          [[ -n "$selected" ]] || return 0

          echo "$selected"
          if read -q "reply?Delete the above entries from atuin and zsh history? [y/N] "; then
            echo
          else
            echo
            return 0
          fi

          while IFS= read -r line; do
            [[ -n "$line" ]] && targets+=("$line")
          done <<< "$selected"
        fi

        fc -W

        for target in "''${targets[@]}"; do
          if command -v atuin >/dev/null 2>&1; then
            atuin search --delete "$target" >/dev/null 2>&1 || true
          fi

          if [[ -f "$histfile" ]]; then
            perl -i.bak -e '
              my $pat = shift;
              my $skip = 0;
              while (<>) {
                if (/^: \d+:\d+;(.*)/s) {
                  $skip = (index($_, $pat) != -1);
                } elsif ($skip && (/^\s/ || /\\$/)) {
                  next;
                } else {
                  $skip = (index($_, $pat) != -1);
                }
                print unless $skip;
              }
            ' "$target" "$histfile"
            rm -f "''${histfile}.bak"
          fi
          echo "Deleted from history: $target"
        done

        fc -R
      }
    '';
  };

  home.file.".zshenv".enable = false;
}
