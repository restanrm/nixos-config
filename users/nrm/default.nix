{
  pkgs,
  context ? {
    work = false;
    hostType = "desktop";
  },
  ...
}: {
  xdg.enable = true;

  home.username = "nrm";
  home.homeDirectory = "/home/nrm";
  home.stateVersion = "26.05";
  # home.profileDirectory = "~/.nix-profile";
  # home.sessionPath = [ "~/.nix-profile/bin" ];

  imports = [
    ../../modules/home
  ];

  # Pass context to modules
  _module.args.context = context;
}
