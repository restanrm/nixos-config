{pkgs, ...}: {
  imports = [../../modules/system/common/fonts.nix];

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = "tortuga";
  networking.networkmanager.enable = true;

  services.openssh = {
    enable = true;
    openFirewall = true;
    settings = {
      AllowUsers = ["nrm@192.168.1.0/24"];
      PermitRootLogin = "no";
      PubkeyAuthentication = true;
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
    };
  };

  services.displayManager = {
    gdm.enable = true;
    gdm.autoSuspend = false;
    autoLogin = {
      enable = true;
      user = "nrm";
    };
  };
  services.desktopManager.gnome.enable = true;
  # Keep SSH reachable even when GNOME sees no local input.
  programs.dconf.profiles.user.databases = [
    {
      settings."org/gnome/settings-daemon/plugins/power".sleep-inactive-ac-type = "nothing";
      lockAll = true;
    }
  ];
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    pulse.enable = true;
  };

  users.users.nrm = {
    isNormalUser = true;
    extraGroups = ["wheel" "networkmanager"];
    shell = pkgs.zsh;
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIP4rkqMZhakUSRiRxZylyIMIejgzs4uNo6plhB+xfQR4 nrm@thinkpad-ara"
    ];
  };

  programs.zsh.enable = true;
  programs.zsh.enableGlobalCompInit = false;
  programs.firefox.enable = true;
  environment.systemPackages = [
    (pkgs.chromium.override {enableWideVine = true;})
    pkgs.pavucontrol
  ];
  virtualisation.podman.enable = true;
  nix.settings.experimental-features = ["nix-command" "flakes"];
  nixpkgs.config.allowUnfree = true;
  system.stateVersion = "26.11";
}
