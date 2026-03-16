{...}: {
  wayland.windowManager.hyprland = {
    settings = {
      windowrule = [
        "match:class org.pulseaudio.pavucontrol, float on"
        "match:fullscreen 1, border_color rgb(FF0000) rgb(880808)"
      ];
    };
  };
}
