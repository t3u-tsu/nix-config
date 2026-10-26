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
                  var lines = content.split(u'\n')
                  var in_fence = false
                  var fence = ""
                  var out = []
                  for line in (lines) {
                    var trimmed = line.trim()
                    var marker = ""
                    if (len(trimmed) >= 3 and (trimmed[0:3] === '```' or trimmed[0:3] === '~~~')) {
                      var fence_char = trimmed[0]
                      var width = 0
                      while (width < len(trimmed) and trimmed[width] === fence_char) {
                        setvar width += 1
                      }
                      setvar marker = trimmed[0:width]
                    }
                    if (in_fence) {
                      call out->append(line)
                      if (marker !== "" and marker[0] === fence[0] and len(marker) >= len(fence) and len(marker) === len(trimmed)) {
                        setvar in_fence = false
                      }
                      continue
                    }
                    if (marker !== "") {
                      setvar in_fence = true
                      setvar fence = marker
                      call out->append(line)
                      continue
                    }
                    var chunks = []
                    var in_code = false
                    var i = 0
                    while (i < len(line)) {
                      var is_tick = line[i] === '`'
                      var j = i
                      while (j < len(line) and (line[j] === '`') === is_tick) {
                        setvar j += 1
                      }
                      var chunk = line[i:j]
                      if (is_tick or in_code) {
                        call chunks->append(chunk)
                      } else {
                        call chunks->append(chunk.replace('、', '，').replace('。', '．'))
                      }
                      if (is_tick) {
                        setvar in_code = not in_code
                      }
                      setvar i = j
                    }
                    call out->append(join(chunks, ""))
                  }
                  var fixed = join(out, u'\n')
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
          pkgs.curl
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
          pkgs.openssl
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
