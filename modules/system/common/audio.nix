{...}: {
  # Indispensable pour la découverte des périphériques AirPlay (mDNS/Zeroconf)
  services.avahi = {
    enable = true;
    nssmdns4 = true;
    openFirewall = true;
  };

  services.blueman.enable = true;

  services.pipewire = {
    enable = true;
    pulse.enable = true;
    alsa.enable = true;

    # Configuration directe du module RAOP comme sur votre Arch
    extraConfig.pipewire = {
      "99-airplay" = {
        "context.modules" = [
          {name = "libpipewire-module-raop-discover";}
        ];
      };
      # try to fix sound issues with bluetooth and phone
      "10-bluez" = {
        "monitor.bluez.properties" = {
          "bluez5.enable-sbc-xq" = true;
          "bluez5.enable-msbc" = true;
          "bluez5.enable-hw-volume" = true;
          "bluez5.roles" = ["a2dp_sink" "a2dp_source" "hfp_hf" "hfp_ag"];
        };
      };
    };
  };
}
