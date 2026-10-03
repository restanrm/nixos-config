{config, ...}: {
  wayland.windowManager.hyprland.settings.env = map (pair: {_args = pair;}) [
    ["XDG_CURRENT_DESKTOP" "Hyprland"]
    ["XDG_SESSION_TYPE" "wayland"]
    ["XDG_SESSION_DESKTOP" "Hyprland"]
    ["MOZ_ENABLE_WAYLAND" "1"]
    ["EDITOR" "nvim"]
    ["TERMINAL" "alacritty"]
    ["XDG_TERMINAL_EMULATOR" "alacritty"]
    ["NIXPKG_ALLOW_UNFREE" "1"]
    ["GTK_THEME" "Adwaita-dark"]
    ["QT_QPA_PLATFORMTHEME" config.qt.platformTheme.name]
    ["COLOR_SCHEME" "prefer-dark"]
  ];
}
