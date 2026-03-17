{...}: {
  imports = [
    ./audio.nix
    ./fingerprint.nix
    ./fonts.nix
    ./noctalia-dependencies.nix
    ./podman.nix
    ./ssh.nix
    ./yubikey.nix
    ./tailscale.nix
    ./argocd.nix
  ];
}
