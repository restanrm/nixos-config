{pkgs, ...}:
{
  home.packages = with pkgs; [
    # Desktop
    htop
    rofi
    hyprland
    hyprlock
    slurp
    grim
    pipewire
    mako
    playerctl
    brightnessctl
    pavucontrol
    firefox
    waybar
    chromium

    # CLI Tools
    wget
    curl
    vault
    zellij
    ripgrep
    zoxide
    ncdu
    fzf
    viddy
    podman
    podman-compose
    nvd
    kubectl
    kubectl-node-shell
    kubectl-neat
    kubectl-cnpg
    kubectx
    k9s
    stern
    sops
    age
    yq
    jq
    git
    jujutsu
    httpie
    zsh

    # LSP
    nixd

    # Compilation
    gcc
    gnumake
    pkg-config
    automake
    autoconf
    libtool
    openssl
  ];

  programs.zoxide = {
    enable = true;
    enableZshIntegration = true;
    enableBashIntegration = true;
    enableFishIntegration = true;
  };

  programs.chromium.enable = true;
  programs.rofi.enable = true;

  
}
