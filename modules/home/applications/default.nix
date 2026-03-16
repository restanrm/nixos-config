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
    pinniped
    k9s
    stern
    sops
    age
    yq
    jq
    httpie
    zsh
  ];

  programs.chromium.enable = true;
  programs.firefox.enable = true;
}
