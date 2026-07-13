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
      ./applications
      ./hyprland
      ./ssh
      ./noctalia.nix
      ./bitwarden.nix
      #./niri.nix
      ./nvim
      ./ai.nix
      ./alacritty.nix
      ./development.nix
      ./zsh.nix
      ./fish.nix
      ./git.nix
      ./zoxide.nix
      ./dark-theme.nix
      ./openstack-rs.nix
    ]
    ++ lib.optionals context.work [
      ./work.nix
    ];

  # Pass context to modules
  _module.args.context = context;
}
