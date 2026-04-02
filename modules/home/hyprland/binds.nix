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

  noctaliaBind = [
    "$mod,D, exec, noctalia-shell ipc call launcher toggle" # launcher
    "$mod SHIFT,Return, exec, noctalia-shell ipc call launcher toggle" # launcher
    "$mod,M, exec,  noctalia-shell ipc call notifications toggleHistory" # notifications
    "$mod,P, exec,  noctalia-shell ipc call launcher clipboard" # clipboard
    "$mod ALT,P, exec, noctalia-shell ipc call settings toggle" # settings
    # "$mod CTRL,L, exec,  noctalia-shell ipc call sessionMenu lockAndSuspend" # lockscreen
    "$mod,W,  exec,noctalia-shell ipc call wallpaper toggle" # wallpaper
    "$mod,X,  exec, noctalia-shell ipc call sessionMenu toggle" # power menu
    "$mod, code:42, exec,  noctalia-shell ipc call controlCenter toggle" # noctalia control center (mod + ,)
    "$mod CTRL,R, exec,  noctalia-shell ipc call screenRecorder toggle" # screenrecorder
    "$mod SHIFT,R, exec,  restart.noctalia" # restart noctalia shell
    "$mod CTRL, L, exec, loginctl lock-session"
  ];
  standardBind = [
    "$mod,D,exec,$menu"
    "$mod,P,Clipboard History, exec, cliphist list | rofi -dmenu | cliphist decode | wl-copy"
    "$mod CTRL, L, exec, loginctl lock-session"
  ];
in {
  wayland.windowManager.hyprland.settings = {
    bind =
      noctaliaBind
      ++ [
        "$mod, code:36, exec, $terminal"
        "$mod SHIFT, A, killactive,"
        "$mod SHIFT, E, exec, command -v hyprshutdown >/dev/null 2>&1 && hyprshutdown || hyprctl dispatch exit"
        "$mod SHIFT,space,togglefloating,"
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
        ",Print,exec,command grim -g \"$(slurp)\" - | wl-copy"

        # Autotype secrets (Managed script with sleep to allow modifier release)
        # alt + altgr
        "ALT MOD5, u, exec, ${autotype} /home/nrm/.config/secrets/username"
        "ALT MOD5, p, exec, ${autotype} /home/nrm/.config/secrets/password"

        # Verrouillage manuel
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
