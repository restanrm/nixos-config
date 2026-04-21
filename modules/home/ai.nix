{
  pkgs,
  inputs,
  ...
}: {
  home.packages = [
    pkgs.gemini-cli
    pkgs.github-copilot-cli
  ];
}
