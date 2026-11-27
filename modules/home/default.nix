{
  context ? {
    work = false;
    hostType = "desktop";
  },
  lib,
  ...
}: {
  imports =
    [
      ./ssh
      ./nvim
      ./development.nix
      ./zsh.nix
      ./git.nix
      ./zoxide.nix
    ]
    ++ lib.optionals ((context.desktop or "hyprland") == "hyprland") [
      ./applications
      ./hyprland
      ./noctalia.nix
      ./bitwarden.nix
      ./ai.nix
      ./alacritty.nix
      ./fish.nix
      ./dark-theme.nix
      ./openstack-rs.nix
    ]
    ++ lib.optional context.work ./work.nix;

  # Pass context to modules
  _module.args.context = context;
}
