{pkgs, ...}: {
  # super repo with at ton of conifguration tricks :
  # https://gitlab.com/Zaney/zaneyos/-/blob/main/modules/home/hyprland/default.nix?ref_type=heads

  imports = [
    # ./animations.nix
    ./hyprland.nix
    ./binds.nix
    ./env.nix
    ./exec-once.nix
    ./hyprlock.nix
    ./hypridle.nix
    ./inputs.nix
    ./windows.nix
    ./windowrules.nix
  ];
}
