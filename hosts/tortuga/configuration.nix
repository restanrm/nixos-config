{
  lib,
  pkgs,
  ...
}: {
  imports = [../../modules/system/common/fonts.nix];

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = "tortuga";
  networking.networkmanager.enable = true;

  services.displayManager.gdm.enable = true;
  services.desktopManager.gnome.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    pulse.enable = true;
  };

  users.users.nrm = {
    isNormalUser = true;
    extraGroups = ["wheel" "networkmanager"];
    shell = pkgs.zsh;
  };

  programs.zsh.enable = true;
  programs.zsh.enableGlobalCompInit = false;
  programs.firefox.enable = true;
  environment.systemPackages = [pkgs.chromium pkgs.pavucontrol];
  virtualisation.podman.enable = true;
  nix.settings.experimental-features = ["nix-command" "flakes"];
  nixpkgs.config.allowUnfreePredicate = pkg: lib.getName pkg == "vault";
  system.stateVersion = "26.11";
}
