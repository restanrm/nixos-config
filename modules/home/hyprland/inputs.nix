{...}: {
  wayland.windowManager.hyprland.settings = {
    config.input = {
      kb_layout = "fr";
      kb_variant = "bepo";
      follow_mouse = 1;
      sensitivity = 0;
      touchpad = {
        natural_scroll = false;
        disable_while_typing = true;
        tap_to_click = false;
      };
    };
    gesture = {
      fingers = 3;
      direction = "horizontal";
      action = "workspace";
    };
  };
}
