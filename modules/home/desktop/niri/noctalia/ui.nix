{ ... }:

{
  programs.noctalia-shell.settings = {
    # General UI Settings
    general = {
      language = "ja";
      fontDefault = "Noto Sans CJK JP";
      fontFixed = "Noto Sans Mono CJK JP";
      radiusRatio = 1.0;
      animationSpeed = 1.0;
      enableShadows = false;
    };

    # UI Components - Improved layout and visibility
    bar = {
      position = "top";
      floating = false;
      backgroundOpacity = 0.95;
      height = 32;
      marginVertical = 0;
      marginHorizontal = 0;
      density = "compact";
      showCapsule = false;
      
      widgets = {
        left = [
          { id = "Workspace"; labelMode = "name"; showApplications = true; }
          { id = "Launcher"; icon = "noctalia"; }
        ];
        center = [
          { id = "ActiveWindow"; maxWidth = 400; }
        ];
        right = [
          { id = "Network"; displayMode = "alwaysShow"; }
          { id = "Volume"; displayMode = "alwaysShow"; middleClickCommand = "pavucontrol"; }
          { id = "Brightness"; displayMode = "onhover"; }
          { id = "Battery"; displayMode = "onhover"; }
          { id = "Clock"; formatHorizontal = "yyyy/MM/dd (EEE) HH:mm"; }
          { id = "Tray"; drawerEnabled = true; }
          { id = "NotificationHistory"; showUnreadBadge = true; }
          { id = "ControlCenter"; icon = "noctalia"; }
        ];
      };
    };

    # OSD, Notifications, Launcher, Session
    osd = {
      enabled = true;
      location = "bottom_center";
      autoHideMs = 2500;
    };

    notifications = {
      enabled = true;
      location = "top_center";
      normalUrgencyDuration = 5;
      criticalUrgencyDuration = 10;
    };

    appLauncher = {
      position = "center";
      viewMode = "list";
      sortByMostUsed = true;
      enableClipboardHistory = true;
    };

    sessionMenu = {
      position = "center";
      powerOptions = [
        { action = "lock"; enabled = true; }
        { action = "suspend"; enabled = true; }
        { action = "reboot"; enabled = true; }
        { action = "logout"; enabled = true; }
        { action = "shutdown"; enabled = true; }
      ];
    };
  };
}
