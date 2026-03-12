{...}: {
  # Indispensable pour la découverte des périphériques AirPlay (mDNS/Zeroconf)
  services.avahi = {
    enable = true;
    nssmdns4 = true;
    openFirewall = true;
  };

  services.pipewire = {
    enable = true;
    pulse.enable = true;

    # Configuration directe du module RAOP comme sur votre Arch
    extraConfig.pipewire."99-airplay" = {
      "context.modules" = [
        {name = "libpipewire-module-raop-discover";}
      ];
    };
  };
}
