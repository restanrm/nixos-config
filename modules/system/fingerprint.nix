{ pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    fprintd
  ];

  # Activation du service de gestion des empreintes
  services.fprintd.enable = true;


  # Configuration de PAM pour autoriser l'empreinte (non bloquant)
  # Cela permet d'utiliser l'empreinte pour sudo, login, hyprlock, etc.
  security.pam.services.login.fprintAuth = true;
  security.pam.services.sudo.fprintAuth = true;
  security.pam.services.hyprlock.fprintAuth = true; # Pour votre écran de verrouillage
}
