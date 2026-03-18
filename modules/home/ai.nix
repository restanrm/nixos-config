{
  pkgs,
  inputs,
  ...
}: let
  pkgs-copilot = import inputs.nixpkgs-copilot {
    system = pkgs.system;
    config.allowUnfree = true;
  };
in {
  home.packages = [
    pkgs.gemini-cli
    pkgs-copilot.github-copilot-cli
  ];
}
