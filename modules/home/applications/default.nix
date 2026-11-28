{pkgs, ...}: {
  home.packages = with pkgs; [
    # Desktop
    htop
    pipewire
    pavucontrol
    qpwgraph
    libnotify
    evince

    # CLI Tools
    wget
    curl
    vault
    zellij
    ripgrep
    pwgen
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
    kubectl-view-allocations
    kubernetes-helm
    mirrord
    (pkgs.callPackage ./mcli.nix {})
    kubectx
    terraform
    terragrunt
    k9s
    stern
    sops
    age
    yq
    jq
    httpie
    zsh
    gum
    yazi
    fd
    openssl
    ansible
    gcc
    bat

    #random
    id3v2
    yt-dlp

    dig

    # install signal application
    signal-desktop
  ];

  programs.chromium.enable = true;
  programs.firefox = {
    enable = true;
    configPath = ".config/mozilla/firefox";
  };
  programs.rofi.enable = true;
}
