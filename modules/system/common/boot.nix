{
  pkgs,
  boot,
  ...
}: {
  boot.kernelPackages = pkgs.linuxPackages_latest;
}
