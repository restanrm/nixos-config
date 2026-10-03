{pkgs, ...}: let
  autotype = pkgs.writeShellScript "hyprland-autotype" ''
    # Wait for the user to release Alt/AltGr modifiers
    ${pkgs.coreutils}/bin/sleep 0.2
    if [ -f "$1" ]; then
      # Read secret and remove any trailing newline
      SECRET=$(${pkgs.coreutils}/bin/cat "$1" | ${pkgs.coreutils}/bin/tr -d '\n')
      ${pkgs.wtype}/bin/wtype -d 20 "$SECRET"
    fi
  '';
in {
  wayland.windowManager.hyprland.extraConfig = ''
    -- Noctalia / session shortcuts
    hl.bind(mod .. " + D", hl.dsp.exec_cmd("noctalia msg panel-toggle launcher"))
    hl.bind(mod .. " + SHIFT + Return", hl.dsp.exec_cmd("noctalia msg panel-toggle launcher"))
    hl.bind(mod .. " + J", hl.dsp.exec_cmd("bwmenu --auto-lock 86400"))
    hl.bind("CTRL + J", hl.dsp.exec_cmd("bwmenu --auto-lock 86400"))
    hl.bind(mod .. " + M", hl.dsp.exec_cmd("noctalia msg panel-toggle control-center notifications"))
    hl.bind(mod .. " + P", hl.dsp.exec_cmd("noctalia msg panel-toggle clipboard"))
    hl.bind(mod .. " + ALT + P", hl.dsp.exec_cmd("noctalia msg settings-toggle"))
    hl.bind(mod .. " + W", hl.dsp.exec_cmd("noctalia msg panel-toggle wallpaper"))
    hl.bind(mod .. " + X", hl.dsp.exec_cmd("noctalia msg panel-toggle session"))
    hl.bind(mod .. " + code:42", hl.dsp.exec_cmd("noctalia msg panel-toggle control-center"))
    -- Open recording controls without starting a capture unexpectedly.
    hl.bind(mod .. " + CTRL + R", hl.dsp.exec_cmd("noctalia msg plugin alexander/screen-toolkit:service all toggle"))
    -- Avoid the existing SHIFT+R window-swap shortcut.
    hl.bind(mod .. " + CTRL + SHIFT + R", hl.dsp.exec_cmd("systemctl --user restart noctalia.service"))
    -- Retain read-only access to the legacy clipboard database during migration.
    hl.bind(mod .. " + CTRL + P", hl.dsp.exec_cmd("cliphist list | rofi -dmenu | cliphist decode | wl-copy"))
    hl.bind(mod .. " + CTRL + L", hl.dsp.exec_cmd("loginctl lock-session"))

    -- Window management; fullscreen=1 previously meant maximized, not exclusive fullscreen.
    hl.bind(mod .. " + code:36", hl.dsp.exec_cmd(terminal))
    hl.bind(mod .. " + SHIFT + A", hl.dsp.window.close())
    hl.bind(mod .. " + SHIFT + E", hl.dsp.exec_cmd("command -v hyprshutdown >/dev/null 2>&1 && hyprshutdown || hyprctl dispatch 'hl.dsp.exit()'"))
    hl.bind(mod .. " + SHIFT + space", hl.dsp.window.float())
    hl.bind(mod .. " + F", hl.dsp.window.fullscreen({ mode = "maximized" }))
    hl.bind(mod .. " + TAB", hl.dsp.focus({ workspace = "previous" }))
    hl.bind(mod .. " + C", hl.dsp.focus({ direction = "left" }))
    hl.bind(mod .. " + R", hl.dsp.focus({ direction = "right" }))
    hl.bind(mod .. " + S", hl.dsp.focus({ direction = "up" }))
    hl.bind(mod .. " + T", hl.dsp.focus({ direction = "down" }))
    hl.bind(mod .. " + SHIFT + C", hl.dsp.window.swap({ direction = "left" }))
    hl.bind(mod .. " + SHIFT + R", hl.dsp.window.swap({ direction = "right" }))
    hl.bind(mod .. " + SHIFT + S", hl.dsp.window.swap({ direction = "up" }))
    hl.bind(mod .. " + SHIFT + T", hl.dsp.window.swap({ direction = "down" }))
    hl.bind(mod .. " + SHIFT + code:20", hl.dsp.workspace.toggle_special("magic"))
    hl.bind(mod .. " + code:20", hl.dsp.window.move({ workspace = "special:magic", follow = true }))
    hl.bind(mod .. " + CTRL + left", hl.dsp.workspace.move({ monitor = "l" }))
    hl.bind(mod .. " + CTRL + right", hl.dsp.workspace.move({ monitor = "r" }))
    hl.bind("Print", hl.dsp.exec_cmd([[command grim -g "$(slurp)" - | wl-copy]]))

    -- Preserve the delayed autotype script and Alt/AltGr combinations.
    hl.bind("ALT + MOD5 + U", hl.dsp.exec_cmd("${autotype} /home/nrm/.config/secrets/username"))
    hl.bind("ALT + MOD5 + P", hl.dsp.exec_cmd("${autotype} /home/nrm/.config/secrets/password"))

    -- Preserve physical number-row keycodes (10 through 18) under Bépo.
    for workspace = 1, 9 do
      local key = " + code:" .. (workspace + 9)
      hl.bind(mod .. key, hl.dsp.focus({ workspace = workspace }))
      hl.bind(mod .. " + SHIFT" .. key, hl.dsp.window.move({ workspace = workspace, follow = true }))
    end

    hl.bind(mod .. " + mouse:272", hl.dsp.window.drag(), { mouse = true })
    hl.bind(mod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

    -- Repeat/locked behavior matches bindel and bindl respectively.
    hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+"), { locked = true, repeating = true })
    hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"), { locked = true, repeating = true })
    hl.bind("XF86AudioMute", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"), { locked = true, repeating = true })
    hl.bind("XF86AudioMicMute", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"), { locked = true, repeating = true })
    hl.bind("XF86MonBrightnessUp", hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 5%+"), { locked = true, repeating = true })
    hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 5%-"), { locked = true, repeating = true })

    hl.bind("XF86AudioNext", hl.dsp.exec_cmd("playerctl next"), { locked = true })
    hl.bind("XF86AudioPause", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
    hl.bind("XF86AudioPlay", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
    hl.bind("XF86AudioPrev", hl.dsp.exec_cmd("playerctl previous"), { locked = true })
  '';
}
