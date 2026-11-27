{...}: {
  imports = [
    ./hardware-configuration.nix
    ./configuration.nix
    ../../modules/system/gaming.nix
  ];
}
