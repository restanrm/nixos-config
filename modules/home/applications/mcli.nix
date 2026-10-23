{
  lib,
  stdenvNoCC,
  fetchurl,
}:
stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "mcli";
  version = "20261018000000.0.0";

  src = fetchurl {
    url = "https://github.com/pgsty/mc/releases/download/RELEASE.2026-10-18T00-00-00Z/mcli_${finalAttrs.version}_linux_amd64.tar.gz";
    hash = "sha256-tTkqZC28loW1F+6QHwMtHV6I9BcEQ28PCN3mBgtXfbM=";
  };

  sourceRoot = ".";
  dontConfigure = true;
  dontBuild = true;

  installPhase = ''
    runHook preInstall
    install -Dm755 mcli "$out/bin/mcli"
    ln -s mcli "$out/bin/mc"
    install -Dm644 -t "$out/share/doc/mcli" LICENSE NOTICE CREDITS
    runHook postInstall
  '';

  doInstallCheck = true;
  installCheckPhase = ''
    runHook preInstallCheck
    export HOME="$TMPDIR"
    "$out/bin/mcli" --version | grep -F 'RELEASE.2026-10-18T00-00-00Z'
    "$out/bin/mc" --version | grep -F 'RELEASE.2026-10-18T00-00-00Z'
    runHook postInstallCheck
  '';

  meta = {
    description = "PGSTY-maintained MinIO client fork for S3-compatible storage";
    homepage = "https://github.com/pgsty/mc";
    license = lib.licenses.agpl3Plus;
    sourceProvenance = [lib.sourceTypes.binaryNativeCode];
    platforms = ["x86_64-linux"];
    mainProgram = "mcli";
  };
})
