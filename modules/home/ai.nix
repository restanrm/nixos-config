{
  pkgs,
  inputs,
  ...
}: {
  home.packages = with pkgs; [
    gemini-cli
    github-copilot-cli
    rtk
    ollama
  ];
}
