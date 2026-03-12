{pkgs, ...}: {
  home.packages = with pkgs; [
    # Desktop
    htop
    pipewire
    pavucontrol
    qpwgraph
    firefox
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
    httpie
    zsh
  ];

  programs.zoxide = {
    enable = true;
    enableZshIntegration = true;
    enableBashIntegration = true;
    enableFishIntegration = true;
  };

  programs.chromium.enable = true;
}
