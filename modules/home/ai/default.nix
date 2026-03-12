{pkgs, ...}:
{
  home.packages = with pkgs; [
    # Desktop
    gemini-cli
    github-copilot-cli
  ];
}
