{pkgs, ...}: {
  xdg.configFile."gh-dash/config.yml".text = ''
    pager:
      diff: diffnav
  '';

  home.packages = with pkgs; [
    # LSP
    nixd

    # python
    ty
    ruff

    # rust
    cargo

    # Golang
    go
    diffnav

    # Nix
    alejandra
  ];
}
