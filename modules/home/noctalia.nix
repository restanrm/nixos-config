{
  pkgs,
  inputs,
  ...
}: {
  imports = [
    inputs.noctalia.homeModules.default
  ];

  programs.noctalia-shell = {
    enable = true;
    systemd.enable = true;
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
