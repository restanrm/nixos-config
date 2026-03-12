{...}: 
{
  wayland.windowManager.hyprland = {
      settings = {
        env = [
          "XDG_CURRENT_DESKTOP, Hyprland"
          "XDG_SESSION_TYPE, wayland"
          "XDG_SESSION_DESKTOP, Hyprland"
          "MOZ_ENABLE_WAYLAND, 1"
          "EDITOR, nvim"
          "TERMINAL, alacritty"
          "XDG_TERMINAL_EMULATOR, alacritty"
          "NIXPKG_ALLOW_UNFREE, 1"
        ];
      };
    };

}
