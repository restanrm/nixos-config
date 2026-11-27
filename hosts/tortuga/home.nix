{pkgs, ...}: {
  imports = [../../modules/home/alacritty.nix];

  home.packages = with pkgs; [
    age
    bat
    dig
    jq
    (callPackage ../../modules/home/applications/mcli.nix {})
    pdftk
    pi-coding-agent
    sops
    stern
    uv
    viddy
    wget
    zellij
  ];
}
