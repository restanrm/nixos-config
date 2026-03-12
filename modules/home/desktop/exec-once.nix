{...}:
{
  wayland.windowManager.hyprland.settings = {
      exec-once = [
        "wl-paste --type text --watch cliphist store" # saves text 
        "wl-paste --type image --watch cliphist store" # saves images
        "dbus-update-activation-environment --all --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP"
        "systemctl --user import-environment WAYLAND_DISPLAY XDG_CURRENT_DESKTOP"
        "systemctl --user start hyprpolkitagent"
        "hypridle"
      ];
    };

}
