{ pkgs, ... }:
{
  services.hypridle = {
    enable = true;
    settings = {
      general = {
        after_sleep_cmd = "hyprctl dispatch dpms on";
        before_sleep_cmd = "loginctl lock-session";
        ignore_dbus_inhibit = false;
        lock_cmd = "pidof hyprlock || hyprlock";
      };

      listener = [
        # Réduction de la luminosité (2.5 min)
        {
          timeout = 150;
          on-timeout = "${pkgs.brightnessctl}/bin/brightnessctl set 10%";
          on-resume = "${pkgs.brightnessctl}/bin/brightnessctl set 100%";
        }
        # Verrouillage (5 min)
        {
          timeout = 300;
          on-timeout = "loginctl lock-session";
        }
        # Écran off (10 min)
        {
          timeout = 600;
          on-timeout = "hyprctl dispatch dpms off";
          on-resume = "hyprctl dispatch dpms on";
        }
        # Suspend (20 min)
        {
          timeout = 1200;
          on-timeout = "systemctl suspend";
        }
      ];
    };
  };
}
