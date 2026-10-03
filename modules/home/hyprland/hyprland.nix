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
    ddcutil # manage external screen brightness
  ];

  # programs.hyprlock.enable = true; # Déplacé dans hyprlock.nix
  programs.rofi.enable = true;

  # home.file = {
  #   ".config/hypr/hyprland.conf".source = assets/hyprland.conf;
  # };

  # services.mako = {
  #   enable = false;
  #   settings = {
  #     default-timeout = 10000;
  #     anchor = "bottom-right";
  #   };
  # };

  wayland.windowManager.hyprland = {
    enable = true;
    configType = "lua";
    systemd.enable = true;
    settings = {
      monitor = {
        output = "";
        mode = "preferred";
        position = "auto";
        scale = 1;
      };
      mod._var = "SUPER";
      terminal._var = "alacritty";
    };
  };
}
