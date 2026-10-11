{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:

with lib;
let
  cfg = config.my.home.desktop.dev-tools.ai-tools;
  # Workaround for node-addon-require-builtin failure on NixOS (numtide/llm-agents.nix#9994).
  # Remove this override once upstream merges the fix.
  dsh = inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system}.dsh.overrideAttrs (old: {
    postInstall = (old.postInstall or "") + ''
      substituteInPlace \
        $out/lib/node_modules/@deepseek-ai/dsh/node_modules/@deepseek-ai/dsh-app-boot/lib/index.js \
        --replace-fail \
        'createRequire(import.meta.url)("node-addon-require-builtin")' \
        '{ requireBuiltin: createRequire(import.meta.url) }'
    '';
  });

  deepseek-harness-alias = pkgs.runCommand "deepseek-harness-alias" { } ''
    mkdir -p "$out/bin"
    ln -s "${dsh}/bin/dsh" "$out/bin/deepseek-harness"
  '';
in
{
  config = mkIf cfg.enable {
    home.packages = [
      dsh
      deepseek-harness-alias
    ];
  };
}
