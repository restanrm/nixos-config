{pkgs,...}:
{
  home.packages = with pkgs; [
    grim
    slurp
    wl-clipboard
    cliphist
    playerctl
    brightnessctl
    pavucontrol
    hyprland
  ];

  programs.hyprlock.enable = true;
  programs.rofi.enable = true;
  programs.chromium.enable = true;
  programs.firefox.enable = true;

  home.file = {
    ".config/hypr/hyprland.conf".source = assets/hyprland.conf;
  };

  services.mako = {
    enable = true;
    settings = {
      default-timeout = 10000;
      anchor = "bottom-right";
    };
  };
}
