{
  pkgs,
  inputs,
  ...
}: let
  pinnedPlugins = pkgs.linkFarm "noctalia-plugins" [
    {
      name = "paged-todo";
      path = "${inputs.noctalia-plugins}/paged-todo";
    }
    {
      name = "screen-toolkit";
      path = "${inputs.noctalia-plugins}/screen-toolkit";
    }
  ];
in {
  imports = [
    inputs.noctalia.homeModules.default
  ];

  # Seed only new plugin state; the Todo port handles its own v4 import.
  systemd.user.services.noctalia.Service.ExecStartPre = pkgs.writeShellScript "noctalia-migrate-state" ''
    ${pkgs.python3}/bin/python3 ${../../scripts/migrate-noctalia-state.py} \
      "$HOME/.config/noctalia/plugins/screen-toolkit/settings.json" \
      "''${XDG_STATE_HOME:-$HOME/.local/state}/noctalia/plugins/data/alexander/screen-toolkit"
  '';

  programs.noctalia = {
    enable = true;
    systemd.enable = true;
    checkConfig = true;
    settings = {
      shell = {
        corner_radius_scale = 0.2;
        polkit_agent = true;
        clipboard_enabled = true;
        clipboard_history_max_entries = 750;
        # Do not retain password-manager selections after their owner exits.
        clipboard_keep_from_closed_apps = false;
        date_format = "%m/%d/%Y";
        session.actions = [
          {
            action = "command";
            label = "Lock";
            glyph = "lock";
            command = "loginctl lock-session";
          }
          {action = "logout";}
          # hypridle's logind sleep inhibitor locks before sleep.
          {
            action = "command";
            label = "Lock & suspend";
            glyph = "moon";
            command = "systemctl suspend";
          }
          {action = "reboot";}
          {action = "shutdown";}
        ];
      };

      theme = {
        mode = "dark";
        source = "builtin";
        builtin = "Catppuccin";
      };
      storage.key_source = "secret-service";
      location = {
        auto_locate = false;
        address = "Rennes, France";
      };
      wallpaper = {
        enabled = true;
        directory = "/home/nrm/Pictures/Wallpapers";
        automation.enabled = true;
      };

      # Keep the existing hypridle/hyprlock ownership during migration.
      lockscreen.enabled = false;
      idle.behavior = {
        lock.enabled = false;
        screen-off.enabled = false;
      };

      bar.main = {
        position = "bottom";
        thickness = 25;
        capsule = false;
        start = ["distro-control-center" "network" "bluetooth"];
        center = ["workspaces" "paged-todo" "screen-toolkit"];
        end = ["tray" "notifications" "volume" "brightness" "control-center" "battery" "clock"];
      };
      widget = {
        distro-control-center = {
          type = "control-center";
          custom_image = "${pkgs.nixos-icons}/share/icons/hicolor/scalable/apps/nix-snowflake.svg";
        };
        workspaces = {
          show_labels = true;
        };
        paged-todo.type = "baizhu/paged-todo:bar";
        screen-toolkit.type = "alexander/screen-toolkit:widget";
        tray.drawer = false;
        battery = {
          show_label = true;
          label_content = "percent";
        };
        clock = {
          format = "{:%Y-%m-%d %H:%M:%S}";
          vertical_format = "{:%H %M}";
          font_family = "monospace";
          color = "primary";
        };
      };
      battery.warning_threshold = 30;

      plugins = {
        enabled = ["baizhu/paged-todo" "alexander/screen-toolkit"];
        auto_update = "none";
        source = [
          {
            name = "pinned-community";
            kind = "path";
            location = "${pinnedPlugins}";
            enabled = true;
          }
        ];
      };
      # The paged-todo port imports mutable v4 data on its first start.
      plugin_settings = {
        "baizhu/paged-todo" = {
          show_completed = true;
          export_format = "markdown";
          export_empty_sections = false;
        };
        "alexander/screen-toolkit" = {
          panel-mode = "legacy";
          selected-ocr-lang = "eng";
        };
      };
    };
  };

  # Screen Toolkit uses one native recorder/editor; alternatives are unnecessary.
  home.packages = with pkgs; [
    hyprpicker
    tesseract
    imagemagick
    zbar
    ffmpeg
    bc
    wl-screenrec
    satty
    mpv
    translate-shell
    seahorse
  ];
}
