_:

{
  programs.starship = {
    enable = true;
    enableZshIntegration = true;
    settings = {
      add_newline = false;
      format = ''
        [$username$hostname]($style)$directory$git_branch$git_status$nix_shell$cmd_duration$jobs
        $character
      '';

      character = {
        success_symbol = "[❯](bold green)";
        error_symbol = "[❯](bold red)";
      };

      username = {
        show_always = false;
        format = "[$user]($style)@";
        style_user = "bold brblue";
        style_root = "bold red";
      };

      hostname = {
        ssh_symbol = "  ";
        format = "[$ssh_symbol$hostname]($style) in ";
        style = "bold green";
      };

      directory = {
        truncation_length = 4;
        fish_style_pwd_dir_length = 1;
        style = "bold cyan";
      };

      git_branch = {
        symbol = "  ";
        style = "bold yellow";
        format = "on [$symbol$branch]($style) ";
      };

      git_status = {
        style = "bold red";
        format = "([\\[$all_status$num_status\\]]($style) )";
      };

      nix_shell = {
        symbol = "  ";
        format = "via [$symbol$state]($style) ";
        style = "bold blue";
      };

      cmd_duration = {
        min_time = 2000;
        format = "󱫍  [$duration]($style) ";
        style = "bold yellow";
      };

      jobs = {
        symbol = "󰜎  ";
        style = "bold dimmed white";
        format = "[$symbol$number]($style) ";
      };
    };
  };
}
