{
  inputs,
  pkgs,
  ...
}: {
  services.sekoia-agent = {
    enable = true;
    package = inputs.sekoia-nixpkgs.packages.${pkgs.stdenv.hostPlatform.system}.sekoia-agent.overrideAttrs (finalAttrs: old: {
      version = "1.12.0";
      # shortcut: upstream pins a stale agent-latest; remove when its checksum is fixed.
      src = pkgs.fetchurl {
        url = "https://app.sekoia.io/api/v1/xdr-agent/download/agent-latest";
        hash = "sha256-aTQZqxGiCuBJ6GAxo1IQGrUbOgVTL9avHQfn96eeiA8=";
      };
      doInstallCheck = true;
      installCheckPhase = ''
        runHook preInstallCheck
        grep -aFq 'SEKOIA.IO/agent/config.AgentVersion=v${finalAttrs.version}+' "$out/agent"
        runHook postInstallCheck
      '';
    });
    settings = {
      intakekey = "yGhWnczn1F9BH575xkUGif7pywQoSoGZ";
      roles = [
        "event-collector"
      ];
    };
  };
}
