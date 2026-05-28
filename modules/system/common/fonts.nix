{pkgs, ...}: {
  fonts.packages = with pkgs; [
    nerd-fonts.noto
    nerd-fonts.fira-code
    noto-fonts
    noto-fonts-color-emoji
  ];

  fonts.fontconfig.defaultFonts.emoji = ["Noto Color Emoji"];
}
