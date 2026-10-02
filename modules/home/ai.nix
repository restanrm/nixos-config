{
  pkgs,
  inputs,
  ...
}: {
  home.packages = with pkgs; [
    github-copilot-cli
    rtk
    ollama
  ];
}
