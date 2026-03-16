{pkgs, ...}: {
  environment.systemPackages = with pkgs; [
    fprintd
  ];

  # Activation du service de gestion des empreintes
  services.fprintd.enable = true;

  # Note: Pour les laptops HP/Dell récents, le pilote TOD est souvent nécessaire
  # pour éviter que fprintd ne bloque l'authentification par mot de passe.
  # services.fprintd.tod.enable = true;
  # services.fprintd.tod.driver = pkgs.libfprint-2-tod1-goodix;

  # Configuration de PAM pour autoriser l'empreinte
  security.pam.services.login.fprintAuth = true;
  security.pam.services.sudo.fprintAuth = true;
  security.pam.services.hyprlock.fprintAuth = true; # Pour votre écran de verrouillage
}
