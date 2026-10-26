{ inputs, config, ... }:
let
  flakeConfig = config;
in
{
  imports = [ inputs.git-hooks.flakeModule ];

  perSystem =
    {
      pkgs,
      config,
      system,
      ...
    }:
    let
      pkgsYsh = pkgs.extend flakeConfig.flake.overlays.default;
    in
    {
      formatter = pkgs.nixfmt;

      pre-commit.check.enable = system == "x86_64-linux";

      pre-commit.settings.hooks = {
        nixfmt.enable = true;
        statix.enable = true;
        convco.enable = true;
        # nvfetcher writes `_sources/generated.json` without a trailing newline.
        end-of-file-fixer = {
          enable = true;
          excludes = [ "^_sources/generated\\.(json|nix)$" ];
        };
        trim-trailing-whitespace.enable = true;
        # shellcheck -x follows source= directives.
        shellcheck = {
          enable = true;
          files = "\\.sh$";
          entry = "${pkgs.shellcheck}/bin/shellcheck -x";
        };
        ysh-check = {
          enable = true;
          name = "ysh-check";
          description = "Check syntax of YSH scripts";
          files = "\\.ysh$";
          entry = "${pkgs.oils-for-unix}/bin/ysh -n";
        };
        ja-punctuation = {
          enable = true;
          name = "ja-punctuation";
          description = "Replace 、。 with ，． in Japanese docs";
          files = "\\.md$";
          # Rewrites files in place and exits 1 when it changed one, so the fix is re-staged.
          entry = "${
            pkgsYsh.writeYshApplication {
              name = "fix-ja-punctuation";
              text = ''
                var status = 0
                for f in (ARGV) {
                  var content = ""
                  read --all (&content) < $f
                  var fixed = content.replace("、", "，").replace("。", "．")
                  if (fixed !== content) {
                    echo $"FIXED: $f replaced 、。 with ，．"
                    write --end "" -- $fixed > $f
                    setvar status = 1
                  }
                }
                exit $status
              '';
            }
          }/bin/fix-ja-punctuation";
        };
        docs-check = {
          enable = true;
          name = "docs-check";
          description = "Lint markdown prose and validate relative links and heading anchors";
          files = "\\.md$";
          entry = "${pkgs.perl}/bin/perl scripts/docs/check-docs.pl";
        };
      };

      devShells.default = pkgs.mkShell {
        packages = [
          config.agenix-rekey.package
          pkgs.age
          pkgs.bitwarden-cli
          pkgs.cloudflared
          pkgs.convco
          pkgs.gh
          pkgs.git
          pkgs.just
          pkgs.mkpasswd
          pkgs.nebula
          pkgs.nh
          pkgs.nix-tree
          pkgs.nvfetcher
          pkgs.oils-for-unix
          pkgs.opentofu
          pkgs.perl
          pkgs.ssh-to-age
        ];
        inputsFrom = [ config.pre-commit.devShell ];
      };

      devShells.convco = pkgs.mkShell {
        packages = [ pkgs.convco ];
      };
    };
}
