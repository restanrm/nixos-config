{pkgs, ...}: {
  xdg.enable = true;

  home.username = "nrm";
  home.homeDirectory = "/home/nrm";
  home.stateVersion = "25.11";
  # home.profileDirectory = "~/.nix-profile";
  # home.sessionPath = [ "~/.nix-profile/bin" ];

  imports = [
    ../../modules/home
  ];
}
