{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.my.home.desktop.dev-tools.neovim;
  juliaPkg = config.my.home.desktop.dev-tools.julia.package;
  palette = import ../../../../lib/palette.nix;

  juliaLspBuildSysimage = pkgs.writeYshApplication {
    name = "julia-lsp-build-sysimage";
    runtimeInputs = [ juliaPkg ];
    text = ''
      var depot = "$HOME/.julia"
      var depot_env = get(ENV, 'JULIA_DEPOT_PATH', "")
      if (depot_env !== "") {
        var first = depot_env.split(':')[0]
        if (first !== "") {
          setvar depot = first
        }
      }
      var env_dir = "$depot/environments/nvim-lspconfig"
      var builder_dir = "$depot/environments/nvim-lspconfig-builder"
      var sysimage = "$env_dir/languageserver.so"

      if ! test -f "$builder_dir/Project.toml" {
        julia --project="$builder_dir" -e 'using Pkg; Pkg.add(["LanguageServer", "PackageCompiler"])'
      }

      julia --project="$builder_dir" -e 'using Pkg; Pkg.instantiate(); using PackageCompiler; PackageCompiler.create_sysimage(["LanguageServer"]; sysimage_path=ARGS[1], project=ARGS[2])' \
        "$sysimage" "$env_dir"
    '';
  };
in
{
  options.my.home.desktop.dev-tools.neovim = {
    enable = lib.mkEnableOption "Neovim text editor";
    julia.enable = lib.mkEnableOption "Julia LSP and Tree-sitter support for Neovim";
  };

  config = lib.mkIf cfg.enable {
    my.home.desktop.dev-tools.neovim.julia.enable =
      lib.mkDefault config.my.home.desktop.dev-tools.julia.enable;

    home = {
      sessionVariables = {
        EDITOR = "nvim";
        VISUAL = "nvim";
      };
      packages = lib.mkIf cfg.julia.enable [ juliaLspBuildSysimage ];
      activation.installJuliaLanguageServer = lib.mkIf cfg.julia.enable (
        lib.hm.dag.entryAfter [ "writeBoundary" ] ''
          env_dir="$HOME/.julia/environments/nvim-lspconfig"
          if ! grep -q "LanguageServer" "$env_dir/Project.toml" 2>/dev/null; then
            ${juliaPkg}/bin/julia --project="$env_dir" -e 'using Pkg; Pkg.add("LanguageServer"); Pkg.precompile()' \
              || echo "warning: failed to install Julia LanguageServer.jl"
          fi
        ''
      );
    };

    programs.neovim = {
      enable = true;
      viAlias = true;
      vimAlias = true;
      extraPackages = with pkgs; [
        gcc
        lua-language-server
        tree-sitter
        websocat
      ];
      initLua = ''
        vim.g.nix_palette = {
          bg = "${palette.bg}",
          bg2 = "${palette.bg2}",
          bg3 = "${palette.bg3}",
          dim = "${palette.dim}",
          fg = "${palette.fg}",
          fg2 = "${palette.fg2}",
          primary = "${palette.primary}",
          secondary = "${palette.secondary}",
          tertiary = "${palette.tertiary}",
          err = "${palette.err}",
        }
      ''
      + builtins.readFile ./config/init.lua;
    };

    xdg.configFile = {
      "nvim/lua".source = ./config/lua;
      "nvim/after".source = ./config/after;
      "nvim/parser/julia.so" = lib.mkIf cfg.julia.enable {
        source = "${pkgs.tree-sitter-grammars.tree-sitter-julia}/parser";
      };
    };
  };
}
