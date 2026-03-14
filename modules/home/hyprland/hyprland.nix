{pkgs, ...}: {
  # super repo with at ton of conifguration tricks :
  # https://gitlab.com/Zaney/zaneyos/-/blob/main/modules/home/hyprland/default.nix?ref_type=heads

  home.packages = with pkgs; [
    grim
    slurp
    wl-clipboard
    waybar
    rofi
    cliphist
    playerctl
    brightnessctl
    pavucontrol
    playerctl
    brightnessctl
  ];

  # programs.hyprlock.enable = true; # Déplacé dans hyprlock.nix
  programs.rofi.enable = true;

  # home.file = {
  #   ".config/hypr/hyprland.conf".source = assets/hyprland.conf;
  # };

  services.mako = {
    enable = true;
    settings = {
      default-timeout = 10000;
      anchor = "bottom-right";
    };
  };

  wayland.windowManager.hyprland = {
    enable = true;
    systemd.enable = true;
    settings = {
      monitor = ",preferred,auto,1";

      "$mod" = "SUPER";
      "$terminal" = "alacritty";
      "$menu" = "rofi -show drun";
    };
  };
}
