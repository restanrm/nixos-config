{pkgs, ...}: {
  environment.systemPackages = with pkgs; [
    python3
    uv
  ];

  programs.nix-ld.enable = true;
}
