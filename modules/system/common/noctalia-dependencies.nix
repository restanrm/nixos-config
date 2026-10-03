{pkgs, ...}: {
  networking.networkmanager.enable = true;
  hardware.bluetooth.enable = true;
  #services.power-profiles-daemon.enable = true;
  services.tuned.enable = true;
  services.upower.enable = true;
  # V5 encrypts clipboard history through the desktop Secret Service.
  services.gnome.gnome-keyring.enable = true;
  # Keep the existing OpenSSH agent rather than replacing it with GCR.
  services.gnome.gcr-ssh-agent.enable = false;
  security.pam.services.greetd.enableGnomeKeyring = true;
}
