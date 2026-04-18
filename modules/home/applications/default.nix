{pkgs, ...}: {
  home.packages = with pkgs; [
    # Desktop
    htop
    pipewire
    pavucontrol
    qpwgraph
    libnotify

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
    kubernetes-helm
    mirrord
    minio-client
    kubectx
    pinniped
    terraform
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

    github-cli
    dig

    # install signal application
    signal-desktop
  ];

  programs.chromium.enable = true;
  programs.firefox.enable = true;
  programs.rofi.enable = true;
}
