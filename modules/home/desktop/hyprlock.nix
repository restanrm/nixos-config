{ ... }:
{
  programs.hyprlock = {
    enable = true;
    settings = {
      general = {
        disable_loading = true;
        hide_cursor = true;
        no_fade_in = false;
      };

      background = [
        {
          path = "screenshot"; # Utilise une capture d'écran floutée
          blur_passes = 3;
          blur_size = 8;
        }
      ];

      input-field = [
        {
          size = "200, 50";
          position = "0, -80";
          monitor = "";
          dots_center = true;
          fade_on_empty = false;
          font_color = "rgb(202, 211, 245)";
          inner_color = "rgb(91, 96, 120)";
          outer_color = "rgb(24, 25, 38)";
          outline_thickness = 5;
          placeholder_text = "Empreinte ou Mot de passe...";
          shadow_passes = 2;
        }
      ];

      label = [
        {
          text = "$TIME";
          color = "rgb(202, 211, 245)";
          font_size = 64;
          font_family = "Noto Sans Nerd Font";
          position = "0, 80";
          halign = "center";
          valign = "center";
        }
      ];
    };
  };
}
