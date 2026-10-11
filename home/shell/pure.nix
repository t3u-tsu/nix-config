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
  '';
}
