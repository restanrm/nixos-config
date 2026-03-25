{...}: {
  wayland.windowManager.hyprland.settings = {
    input = {
      kb_layout = "fr";
      kb_variant = "bepo";
      follow_mouse = 1;
      sensitivity = 0;
      touchpad = {
        natural_scroll = false;
        disable_while_typing = true;
        tap-to-click = false;
      };
    };
    gesture = "3, horizontal, workspace";
  };
}
