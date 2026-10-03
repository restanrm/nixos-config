{...}: {
  wayland.windowManager.hyprland.settings.window_rule = [
    {
      match.class = "org.pulseaudio.pavucontrol";
      float = true;
    }
    {
      match.fullscreen = true;
      border_color = "rgb(FF0000) rgb(880808)";
    }
  ];
}
