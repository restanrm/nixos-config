{pkgs, ...}: {
  home.packages = with pkgs; [
    # LSP
    nixd

    # python
    ty
    ruff

    # rust
    cargo

    # Golang

    # Nix
    alejandra
  ];
}
