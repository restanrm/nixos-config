{...}: {
  wayland.windowManager.hyprland.settings = {
    bind =
      [
        "$mod, code:36, exec, $terminal"
        "$mod SHIFT, A, killactive,"
        "$mod, E, exec, command -v hyprshutdown >/dev/null 2>&1 && hyprshutdown || hyprctl dispatch exit"
        "$mod SHIFT,space,togglefloating,"
        "$mod,D,exec,$menu"
        "$mod,P,pseudo,"
        "$mod,J,layoutmsg,togglesplit"
        "$mod,F,fullscreen,1"
        "$mod,TAB,workspace,previous"
        "$mod,c,movefocus,l"
        "$mod,r,movefocus,r"
        "$mod,s,movefocus,u"
        "$mod,t,movefocus,d"
        "$mod SHIFT,c,swapwindow,l"
        "$mod SHIFT,r,swapwindow,r"
        "$mod SHIFT,s,swapwindow,u"
        "$mod SHIFT,t,swapwindow,d"
        "$mod SHIFT, code:20 ,togglespecialworkspace,magic"
        "$mod, code:20 ,movetoworkspace,special:magic"
        "$mod CTRL, left, movecurrentworkspacetomonitor, l"
        "$mod CTRL, right, movecurrentworkspacetomonitor, r"

        # Verrouillage manuel
        "$mod CTRL, L, exec, loginctl lock-session"
        ",XF86ScreenLock, exec, loginctl lock-session"
      ]
      ++ (
        builtins.concatLists (builtins.genList (i: let
            ws = i + 1;
          in [
            "$mod, code:1${toString i}, workspace, ${toString ws}"
            "$mod SHIFT, code:1${toString i}, movetoworkspace, ${toString ws}"
          ])
          9)
      );
    bindm = [
      "$mod, mouse:272, movewindow"
      "$mod, mouse:273, resizewindow"
    ];
    bindel = [
      ",XF86AudioRaiseVolume, exec, wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+"
      ",XF86AudioLowerVolume, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"
      ",XF86AudioMute, exec, wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"
      ",XF86AudioMicMute, exec, wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"
      ",XF86MonBrightnessUp, exec, brightnessctl -e4 -n2 set 5%+"
      ",XF86MonBrightnessDown, exec, brightnessctl -e4 -n2 set 5%-"
    ];
    bindl = [
      ",XF86AudioNext, exec, playerctl next"
      ",XF86AudioPause, exec, playerctl play-pause"
      ",XF86AudioPlay, exec, playerctl play-pause"
      ",XF86AudioPrev, exec, playerctl previous"
    ];
  };
}
