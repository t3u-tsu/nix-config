{
  lib,
  stdenv,
  fetchurl,
}:

# Upstream's own flake compiles the Rust workspace, so every lock bump ran a
# full cargo build. The release asset is a static-pie musl binary: no loader
# or shared-library fixups, and rustc never runs.
stdenv.mkDerivation (finalAttrs: {
  pname = "codewhale";
  version = "0.10.0";

  src = fetchurl {
    url = "https://github.com/Hmbown/Codewhale/releases/download/v${finalAttrs.version}/codewhale-linux-x64";
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
})
