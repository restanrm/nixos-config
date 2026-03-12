{pkgs, ...}: {
  virtualisation.podman.enable = true;
  virtualisation.podman.dockerCompat = true;
  virtualisation.podman.dockerSocket.enable = true;

  environment.systemPackages = with pkgs; [
    podman-compose
  ];
}
