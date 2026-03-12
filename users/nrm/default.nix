{pkgs, ...}: {
  xdg.enable = true;

  home.username = "nrm";
  home.homeDirectory = "/home/nrm";
  home.stateVersion = "25.11";
  # home.profileDirectory = "~/.nix-profile";
  # home.sessionPath = [ "~/.nix-profile/bin" ];

  imports = [
    ../../modules/home/applications
    ../../modules/home/alacritty
    ../../modules/home/desktop
    ../../modules/home/shell
    ../../modules/home/git
    ../../modules/home/nvim
    ../../modules/home/ai
    ../../modules/home/development
  ];
}
