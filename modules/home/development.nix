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
}
