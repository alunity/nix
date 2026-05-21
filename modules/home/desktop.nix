{
  config,
  lib,
  pkgs,
  osConfig,
  ...
}:

let
  # osConfig gives us access to the system-level configuration (configuration.nix)
  # This way, if my.desktop.xfce.enable is true in the system, it automatically applies here too!
  sysCfg = osConfig.my.desktop;

  # Here we define the custom package snippet you found online
  indigoMagicDark = pkgs.stdenvNoCC.mkDerivation {
    pname = "indigo-magic-dark";
    version = "unstable-2026-05-17";

    src = pkgs.fetchurl {
      url = "https://www.opencode.net/iwonbigbro/indigomagic-dark/-/archive/main/indigomagic-dark-main.tar.gz";
      hash = "sha256-M7fmTQ+soMsG5BlSg4BwuD2mvU6owilgeU2ps/isb84=";
    };

    installPhase = ''
      mkdir -p $out/share/themes/IndigoMagicDark
      cp -r gtk-2.0 gtk-3.0 xfwm4 $out/share/themes/IndigoMagicDark/
    '';
  };
in
{
  config = lib.mkMerge [
    # --- GNOME Home Manager Configuration ---
    (lib.mkIf sysCfg.gnome.enable {
      # You could add GNOME extensions, dconf settings, etc. here
      # For example, what you currently have in home.nix could be moved here later
    })

    # --- XFCE Home Manager Configuration ---
    (lib.mkIf sysCfg.xfce.enable {
      # Ensure the package is installed
      home.packages = [
        indigoMagicDark
        pkgs.chicago95
      ];

      # Apply it to GTK applications
      gtk = {
        enable = true;
        iconTheme = {
          name = "Chicago95";
          package = pkgs.chicago95;
        };
        theme = {
          name = "IndigoMagicDark";
          package = indigoMagicDark;
        };
        gtk4.theme = null;
        gtk3.extraConfig = {
          gtk-application-prefer-dark-theme = 0;
        };
      };

      # Apply it to XFCE specifically via xfconf
      xfconf.settings = {
        xfwm4 = {
          # XFCE Window Manager theme
          "general/theme" = "IndigoMagicDark";
          "general/workspace_count" = 4;
          "general/use_compositing" = false;
        };
        xsettings = {
          # GTK Theme Name for XFCE sessions
          "Net/ThemeName" = "IndigoMagicDark";
        };
        xfce4-keyboard-shortcuts = {
          # Application Shortcuts
          "commands/custom/<Alt>Return" = "ghostty";
          "commands/custom/<Alt>e" = "thunar";
          "commands/custom/<Alt>c" = "google-chrome-stable";
          "commands/custom/<Alt>d" = "xfce4-appfinder";
          "commands/custom/<Alt><Shift>s" = "xfce4-screenshooter -r -c";
          "commands/custom/<Alt><Shift>plus" = "systemctl suspend";

          # Window Manager Shortcuts
          "xfwm4/custom/<Alt>F4" = ""; # Explicitly unbind the default
          "xfwm4/custom/<Alt>q" = "close_window_key";

          # Maximize and Fullscreen
          "xfwm4/custom/<Alt>m" = "maximize_window_key";
          "xfwm4/custom/<Alt><Shift>m" = "fullscreen_key";

          # Snapping (Tiling)
          "xfwm4/custom/<Alt><Shift>h" = "tile_left_key";
          "xfwm4/custom/<Alt><Shift>l" = "tile_right_key";

          # Workspace Switching
          "xfwm4/custom/<Alt>1" = "workspace_1_key";
          "xfwm4/custom/<Alt>2" = "workspace_2_key";
          "xfwm4/custom/<Alt>3" = "workspace_3_key";
          "xfwm4/custom/<Alt>4" = "workspace_4_key";

          # Move Windows to Workspaces
          "xfwm4/custom/<Alt><Shift>1" = "move_window_workspace_1_key";
          "xfwm4/custom/<Alt><Shift>2" = "move_window_workspace_2_key";
          "xfwm4/custom/<Alt><Shift>3" = "move_window_workspace_3_key";
          "xfwm4/custom/<Alt><Shift>4" = "move_window_workspace_4_key";
        };
        xfce4-desktop = {
          # Setting wallpaper across common monitor identifiers
          "backdrop/screen0/monitor0/workspace0/last-image" =
            "${pkgs.nixos-artwork.wallpapers.nineish-dark-gray.src}";
          "backdrop/screen0/monitor1/workspace0/last-image" =
            "${pkgs.nixos-artwork.wallpapers.nineish-dark-gray.src}";
          "backdrop/screen0/monitorVirtual1/workspace0/last-image" =
            "${pkgs.nixos-artwork.wallpapers.nineish-dark-gray.src}";
          "backdrop/screen0/monitorVirtual2/workspace0/last-image" =
            "${pkgs.nixos-artwork.wallpapers.nineish-dark-gray.src}";
          "backdrop/screen0/monitoreDP-1/workspace0/last-image" =
            "${pkgs.nixos-artwork.wallpapers.nineish-dark-gray.src}";
        };
        xfce4-panel = {
          "configver" = 2;
          "panels" = [
            1
            2
          ];
          "panels/dark-mode" = true;
          "panels/panel-1/icon-size" = 16;
          "panels/panel-1/length" = 100;
          "panels/panel-1/plugin-ids" = [
            2
            7
            9
            3
            4
            6
            5
            19
            1
            8
            10
          ];
          "panels/panel-1/position" = "p=6;x=960;y=20";
          "panels/panel-1/position-locked" = true;
          "panels/panel-1/size" = 26;
          "panels/panel-2/autohide-behavior" = 1;
          "panels/panel-2/length" = 1;
          "panels/panel-2/plugin-ids" = [
            11
            12
            13
            14
            15
            16
            17
            18
          ];
          "panels/panel-2/position" = "p=10;x=0;y=0";
          "panels/panel-2/position-locked" = true;
          "panels/panel-2/size" = 48;
          "plugins/plugin-1" = "pulseaudio";
          "plugins/plugin-2" = "tasklist";
          "plugins/plugin-2/grouping" = 1;
          "plugins/plugin-3" = "separator";
          "plugins/plugin-3/expand" = true;
          "plugins/plugin-3/style" = 0;
          "plugins/plugin-4" = "pager";
          "plugins/plugin-5" = "separator";
          "plugins/plugin-5/style" = 0;
          "plugins/plugin-6" = "systray";
          "plugins/plugin-6/square-icons" = true;
          "plugins/plugin-7" = "separator";
          "plugins/plugin-7/style" = 0;
          "plugins/plugin-8" = "clock";
          "plugins/plugin-9" = "separator";
          "plugins/plugin-9/style" = 0;
          "plugins/plugin-10" = "actions";
          "plugins/plugin-11" = "showdesktop";
          "plugins/plugin-12" = "separator";
          "plugins/plugin-13" = "launcher";
          "plugins/plugin-14" = "launcher";
          "plugins/plugin-15" = "launcher";
          "plugins/plugin-16" = "launcher";
          "plugins/plugin-17" = "separator";
          "plugins/plugin-18" = "directorymenu";
          "plugins/plugin-19" = "power-manager-plugin";
        };
      };

      services.redshift = {
        enable = true;
        tray = false;
        provider = "manual";
        latitude = 51.4625;
        longitude = 0.0370;
        temperature = {
          day = 6500;
          night = 3500;
        };
      };

      services.picom = {
        enable = true;
        backend = "glx";
        vSync = true;
      };

      xdg.portal = {
        enable = true;
        extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
        config.common.default = "*";
      };
    })
  ];
}
