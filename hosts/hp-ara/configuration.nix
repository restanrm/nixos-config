{
  config,
  lib,
  pkgs,
  ...
}: {
  imports = [
    ../../modules/system/podman.nix
    ../../modules/system/fonts.nix
    ../../modules/system/audio.nix
    ../../modules/system/fingerprint.nix
    ../../modules/system/ssh.nix
    ../../modules/system/yubikey.nix
  ];

  # Bootloader
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Networking
  networking.hostName = "laptop-ara";
  networking.networkmanager.enable = true;

  # Correctif pour xdg.portal + Home Manager
  environment.pathsToLink = ["/share/applications" "/share/xdg-desktop-portal"];

  # Localization
  time.timeZone = "Europe/Paris";
  i18n.defaultLocale = "fr_FR.UTF-8"; # Optionnel: passage en français par défaut

  # Hardware
  hardware.bluetooth.enable = true;
  hardware.graphics.enable = true;
  console.useXkbConfig = true;

  # Nix Settings
  nix.settings.experimental-features = ["flakes nix-command"];
  nix.settings.download-buffer-size = 536870912; # 512MB
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 15d";
  };

  # X11 / Keymap
  services.xserver.xkb.layout = "fr";
  services.xserver.xkb.variant = "bepo";
  services.printing.enable = true;

  # User Configuration
  users.users.nrm = {
    isNormalUser = true;
    extraGroups = ["wheel"];
    shell = pkgs.zsh; # Définit ZSH comme shell par défaut au niveau système
  };

  # System Packages (Minimal)
  environment.systemPackages = with pkgs; [
    neovim # Gardé en système pour les réparations d'urgence
    wget
    curl
    git
  ];

  programs.zsh.enable = true;
  programs.dconf.enable = true;

  # Security & Management
  nixpkgs.config.allowUnfree = true;
  system.autoUpgrade = {
    enable = true;
    allowReboot = false;
  };

  system.stateVersion = "25.11";
}
