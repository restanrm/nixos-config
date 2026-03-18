{pkgs, ...}: {
  fonts.packages = with pkgs; [
    nerd-fonts.noto
    nerd-fonts.fira-code
  ];
}
