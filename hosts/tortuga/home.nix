{pkgs, ...}: {
  imports = [../../modules/home/alacritty.nix];

  programs.zsh.oh-my-zsh.theme = "gallifrey";

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
