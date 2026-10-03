{
  pkgs,
  inputs,
  ...
}: let
  system = pkgs.stdenv.hostPlatform.system;
  legacyPkgs = inputs.noctalia-nixpkgs.legacyPackages.${system};
in {
  imports = [
    inputs.noctalia.homeModules.default
  ];

  programs.noctalia-shell = {
    enable = true;
    # Frozen glibc cannot load the newer host Mesa; isolate only this shell's EGL driver.
    # ponytail: direct children inherit the EGL override; remove with Noctalia v5.
    package = inputs.noctalia.packages.${system}.default.overrideAttrs (old: {
      # Hyprland's Lua mode also requires Lua dispatcher expressions over IPC.
      patches = (old.patches or []) ++ [./hyprland/noctalia-lua-ipc.patch];
      preFixup =
        old.preFixup
        + ''
          qtWrapperArgs+=(--set __EGL_VENDOR_LIBRARY_FILENAMES "${legacyPkgs.mesa}/share/glvnd/egl_vendor.d/50_mesa.json")
        '';
    });
    systemd.enable = false;
    settings = {
      bar = {
        density = "compact";
        position = "bottom";
        showCapsule = false;
        widgets = {
          left = [
            {
              id = "ControlCenter";
              useDistroLogo = true;
            }
            {id = "Network";}
            {id = "Bluetooth";}
          ];
          center = [
            {
              hideUnoccupied = false;
              id = "Workspace";
              label = "none";
            }
            {id = "plugin:todo";}
            {
              id = "plugin:screen-toolkit";
            }
          ];
          right = [
            {
              id = "Tray";
              drawerEnabled = false;
            }
            {id = "NotificationHistory";}
            {id = "Volume";}
            {id = "Brightness";}
            {id = "ControlCenter";}
            {id = "";}
            {id = "";}
            {
              alwaysShowPercentage = true;
              id = "Battery";
              warningThreshold = 30;
            }
            {
              formatHorizontal = "yyyy-MM-dd HH:mm:ss";
              formatVertical = "HH mm";
              id = "Clock";
              useMonospacedFont = true;
              usePrimaryColor = true;
            }
          ];
        };
      };
      appLauncher = {
        enableClipboardHistory = true;
        enableClipPreview = true;
        clipboardWatchTextCommand = "wl-paste --type text --watch cliphist store";
        clipboardWatchImageCommand = "wl-paste --type image --watch cliphist store";
      };
      wallPaper = {
        automationEnabled = true;
      };
      colorSchemes = {
        predefinedScheme = "Catppuccin";
        darkMode = true;
      };
      general = {
        #avatarImage = "/home/drfoobar/.face";
        radiusRatio = 0.2;
        autoStartAuth = true;
        allowPasswordWithFprintd = true;
      };
      location = {
        monthBeforeDay = true;
        name = "Rennes, France";
      };
      idle = {
        enabled = false;
        screenOffTimeout = 600;
        lockTimeout = 300;
        suspendTimeout = 1800;
        fadeDuration = 5;
        screenOffCommand = "";
        lockCommand = "";
        suspendCommand = "";
        resumeScreenOffCommand = "";
        resumeLockCommand = "";
        resumeSuspendCommand = "";
        customCommands = "[{\"name\":\"reduce brightness\",\"timeout\":150,\"command\":\"brightnessctl set 10%\",\"resumeCommand\":\"brightnessctl set 100%\"}]";
      };
    };
  };
}
