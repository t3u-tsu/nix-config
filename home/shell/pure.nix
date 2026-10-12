{ pkgs, ... }:

{
  programs.zsh.initContent = ''
    # Must run after oh-my-zsh, which overwrites the prompt
    fpath+=("${pkgs.pure-prompt}/share/zsh/site-functions")
    autoload -U promptinit; promptinit

    PURE_CMD_MAX_EXEC_TIME=2
    zstyle :prompt:pure:git:stash show yes

    zstyle :prompt:pure:path color cyan
    zstyle :prompt:pure:git:branch color yellow
    zstyle :prompt:pure:git:dirty color red
    zstyle :prompt:pure:git:arrow color cyan
    zstyle :prompt:pure:execution_time color yellow
    zstyle :prompt:pure:suspended_jobs color white
    zstyle :prompt:pure:prompt:success color green
    zstyle :prompt:pure:prompt:error color red
    zstyle :prompt:pure:user color blue
    zstyle :prompt:pure:host color green
    zstyle :prompt:pure:virtualenv color blue

    prompt pure

    # Fix unevaluated parameter in pure_state[username] falling back to color 0 (black)
    autoload -Uz add-zsh-hook
    _pure_fix_username_color() {
      if [[ -n "$prompt_pure_state[username]" ]]; then
        local user_color="''${prompt_pure_colors[user]}"
        [[ $UID -eq 0 ]] && user_color="''${prompt_pure_colors[user:root]:-default}"
        prompt_pure_state[username]="%F{$user_color}%n%f%F{''${prompt_pure_colors[host]}}@%m%f"
      fi
    }
    add-zsh-hook precmd _pure_fix_username_color
  '';
}
