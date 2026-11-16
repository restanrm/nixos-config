{pkgs, ...}: {
  xdg.configFile."gh-dash/config.yml".text = ''
    pager:
      diff: diffnav
    defaults:
      prApproveComment: ""
  '';

  home.packages = with pkgs; [
    herdr

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
