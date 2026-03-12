{pkgs, ...}: {
  home.packages = with pkgs; [
    # LSP
    nixd

    # python
    uv
    ty
    ruff

    # rust
    cargo

    # Golang

    # Nix
    alejandra
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
