{ inputs, ... }:
{
  imports = [ inputs.git-hooks.flakeModule ];

  perSystem =
    {
      pkgs,
      config,
      system,
      ...
    }:
    {
      formatter = pkgs.nixfmt;

      pre-commit.check.enable = system == "x86_64-linux";

      pre-commit.settings.hooks = {
        nixfmt.enable = true;
        statix.enable = true;
        convco.enable = true;
        ja-punctuation = {
          enable = true;
          name = "ja-punctuation";
          description = "Replace 、。 with ，． in Japanese docs";
          files = "\\.md$";
          entry = "${
            pkgs.writeShellApplication {
              name = "fix-ja-punctuation";
              text = ''
                export LC_ALL=C.UTF-8
                status=0
                for f in "$@"; do
                  if grep -q '[、。]' "$f"; then
                    echo "FIXED: $f replaced 、。 with ，．"
                    sed -i 's/、/，/g; s/。/．/g' "$f"
                    status=1
                  fi
                done
                exit "$status"
              '';
            }
          }/bin/fix-ja-punctuation";
        };
      };

      devShells.default = pkgs.mkShell {
        packages = [
          pkgs.git
          pkgs.nh
          pkgs.nix-tree
          pkgs.opentofu
          pkgs.convco
        ];
        inputsFrom = [ config.pre-commit.devShell ];
      };

      devShells.convco = pkgs.mkShell {
        packages = [ pkgs.convco ];
      };
    };
}
