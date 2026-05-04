{pkgs, ...}: {
  imports = [
    ./audio.nix
    ./boot.nix
    ./fingerprint.nix
    ./fonts.nix
    ./keyd.nix
    ./noctalia-dependencies.nix
    ./podman.nix
    ./ssh.nix
    ./python.nix
    ./yubikey.nix
    ./tailscale.nix
    ./argocd.nix
  ];
}
