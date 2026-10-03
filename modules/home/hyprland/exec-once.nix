{...}: {
  # extraConfig runs after Home Manager's own session-target startup hook.
  wayland.windowManager.hyprland.extraConfig = ''
    hl.on("hyprland.start", function()
      -- Noctalia is supervised by Home Manager's user service.
      hl.exec_cmd("signal-desktop")
      hl.exec_cmd("hypridle")
    end)
  '';
}
