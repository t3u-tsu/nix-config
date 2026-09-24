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
  sources = pkgs.callPackage ../../../../_sources/generated.nix { };

  codewhale = pkgs.stdenv.mkDerivation {
    pname = "codewhale";
    version = removePrefix "v" sources.codewhale.version;
    inherit (sources.codewhale) src;

    dontUnpack = true;
    dontStrip = true;

    installPhase = ''
      runHook preInstall
      install -Dm755 $src $out/bin/codewhale
      runHook postInstall
    '';

    meta = {
      description = "Terminal coding agent for DeepSeek";
      homepage = "https://github.com/Hmbown/CodeWhale";
      license = lib.licenses.mit;
      mainProgram = "codewhale";
      platforms = [ "x86_64-linux" ];
      sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
    };
  };
in
{
  config = mkIf cfg.enable {
    home.packages = [ codewhale ];

    # hush (github:ro80t/hush, MIT): external skill for codewhale's comment ruleset.
    home.file.".codewhale/skills/hush/SKILL.md".source = "${inputs.hush}/skills/hush/SKILL.md";
  };
}
