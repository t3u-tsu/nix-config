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

  version = "0.10.0";

  # Upstream's own flake compiles the Rust workspace, so every lock bump ran a
  # full cargo build. The release asset is a static-pie musl binary: no loader
  # or shared-library fixups, and rustc never runs.
  codewhale = pkgs.stdenv.mkDerivation {
    pname = "codewhale";
    inherit version;

    src = pkgs.fetchurl {
      url = "https://github.com/Hmbown/Codewhale/releases/download/v${version}/codewhale-linux-x64";
      # Published as codewhale-artifacts-sha256.txt in the same release.
      hash = "sha256-xEPCwyx0PdgP9WOXsee7/lWxymMG/1UGW5d7xlXVDtE=";
    };

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
