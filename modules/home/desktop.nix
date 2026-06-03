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

  # Replace the old platinum9Theme block with this:
  macos9Theme = pkgs.stdenvNoCC.mkDerivation {
    pname = "macos9-theme";
    version = "master";
    src = pkgs.fetchFromGitHub {
      owner = "B00merang-Project";
      repo = "Mac-OS-9";
      rev = "master";
      hash = "sha256-gMyLP+7rZdhlCZVVHjzvWvQzvWSLfNZWCvgFUWuMeyw="; # Let it fail to give you the real SRI hash
    };
    installPhase = ''
      mkdir -p $out/share/themes
      if [ -d "Mac-OS-9" ]; then
        cp -a Mac-OS-9 $out/share/themes/
      else
        mkdir -p $out/share/themes/Mac-OS-9
        cp -a * $out/share/themes/Mac-OS-9/
      fi
    '';
  };

  chiNataIcons = pkgs.stdenvNoCC.mkDerivation {
    pname = "chi-nata-icons";
    version = "main";
    src = pkgs.fetchFromGitHub {
      owner = "DawnVespero";
      repo = "Chi-Nata";
      rev = "main";
      sha256 = "sha256-2LlXJ4LtiyiN0vRtQvqTsCBcMDit/UfNa1x/DfKhJWs=";
    };
    installPhase = ''
      mkdir -p $out/share/icons
      if [ -d "Chi-Nata" ]; then
        cp -r Chi-Nata $out/share/icons/
      else
        mkdir -p $out/share/icons/Chi-Nata
        cp -r * $out/share/icons/Chi-Nata/
      fi
    '';
  };

  platinum9Openbox = pkgs.stdenvNoCC.mkDerivation {
    pname = "platinum9-openbox";
    version = "master";
    src = pkgs.fetchFromGitHub {
      owner = "grassmunk";
      repo = "Platinum9";
      rev = "master";
      hash = "sha256-rKM2/Hk1Z/HszSAO0Yf/Zh3d+QGTRJrAE/Mo90Qxgvw=";
    };
    dontCheckForBrokenSymlinks = true;
    installPhase = ''
      mkdir -p $out/share/themes/Platinum9
      # Only copy the openbox theme, ignoring the broken icon folder
      cp -a openbox-3 $out/share/themes/Platinum9/
    '';
  };
in
{
  config = lib.mkMerge [
    # --- GNOME Home Manager Configuration ---
    (lib.mkIf sysCfg.gnome.enable {
      home.packages = with pkgs; [
        adwaita-icon-theme
        gnome-themes-extra
      ];

      # This fixes the "square cursor" and sets a sane GTK theme
      gtk = {
        enable = true;
        theme = {
          name = "adw-gtk3-dark";
          package = pkgs.adw-gtk3;
        };
        cursorTheme = {
          name = "Adwaita";
          package = pkgs.adwaita-icon-theme;
          size = 24;
        };
        iconTheme = {
          name = "Adwaita";
          package = pkgs.adwaita-icon-theme;
        };
        gtk4.theme = null;
      };

      # Tell GNOME specifically to use these via dconf
      dconf.settings = {
        "org/gnome/desktop/interface" = {
          color-scheme = "prefer-dark";
          cursor-theme = "Adwaita";
          gtk-theme = "adw-gtk3-dark";
          icon-theme = "Adwaita";
        };
        "org/gnome/desktop/wm/preferences" = {
          button-layout = "appmenu:minimize,maximize,close";
        };
      };
    })

    # --- XFCE Home Manager Configuration ---
    (lib.mkIf sysCfg.xfce.enable {
      # Ensure the package is installed
      home.packages = [
        indigoMagicDark
        pkgs.chicago95
        pkgs.xfce4-cpufreq-plugin
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
            20
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
          "plugins/plugin-20" = "cpufreq";
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
    (lib.mkIf sysCfg.labwc.enable {
      xdg.enable = true;

      home.pointerCursor = {
        package = pkgs.adwaita-icon-theme;
        name = "Adwaita";
        size = 32;
        gtk.enable = true;
        x11.enable = true;
      };

      home.packages = with pkgs; [
        macos9Theme # The B00merang GTK/Openbox theme
        platinum9Openbox
        chicago95 # Pulling this back in specifically for the Chicago/Geneva fonts
        chiNataIcons
        adwaita-icon-theme
        hicolor-icon-theme
        waybar # Replaces xfce4-panel
        pcmanfm-qt # Replaces thunar & xfce4-desktop
        rofi # Replaces xfce4-appfinder
        grim # Replaces xfce4-screenshooter
        slurp # Region selection for grim
        wbg # Minimal Wayland wallpaper setter
        wlr-randr # To check/set output scaling
        wayland-utils # for wayland-info
        libsecret # for keyring integration
        polkit_gnome # for authentication prompts
        lxappearance # for debugging themes/icons
      ];

      home.file.".themes/Mac-OS-9".source = "${macos9Theme}/share/themes/Mac-OS-9";
      home.file.".icons/Chi-Nata".source = "${chiNataIcons}/share/icons/Chi-Nata";

      gtk = {
        enable = true;
        iconTheme = {
          name = "Chi-Nata";
          package = chiNataIcons;
        };
        theme = {
          name = "Mac-OS-9";
          package = macos9Theme;
        };
        gtk3.extraConfig = {
          gtk-application-prefer-dark-theme = 0; # Classic Mac OS is light mode!
        };
        gtk4.theme = null;
      };

      qt = {
        enable = true;
        platformTheme.name = "gtk";
      };

      programs.waybar = {
        enable = true;
        settings = {
          mainBar = {
            layer = "top";
            position = "top";
            height = 26;
            modules-left = [
              "custom/apple"
              "wlr/taskbar"
            ];
            modules-center = [ "clock" ];
            modules-right = [
              "pulseaudio"
              "network"
              "battery"
              "tray"
            ];

            "custom/apple" = {
              format = "";
              on-click = "rofi -show drun";
              tooltip = false;
            };

            "wlr/taskbar" = {
              format = "{icon}";
              icon-size = 18;
              on-click = "activate";
            };

            "clock" = {
              format = "{:%a %I:%M %p}";
              tooltip-format = "<big>{:%Y %B}</big>\n<tt><small>{calendar}</small></tt>";
            };

            "pulseaudio" = {
              format = "{volume}% {icon}";
              format-bluetooth = "{volume}% {icon}";
              format-muted = "";
              format-icons = {
                "default" = [
                  ""
                  ""
                ];
              };
            };
          };
        };
        style = ''
          * {
            font-family: "Geneva", "Chicago", "Fixedsys", sans-serif;
            font-size: 14px;
            font-weight: bold;
          }
          window#waybar {
            background-color: #cccccc;
            border-bottom: 1px solid #000000;
            color: #000000;
          }
          #custom-apple {
            padding: 0 10px;
            font-size: 18px;
          }
          #clock {
            padding: 0 10px;
          }
          #taskbar button {
            padding: 0 5px;
            border: none;
            background: transparent;
          }
          #taskbar button.active {
            background-color: #999999;
          }
          #pulseaudio, #network, #battery, #tray {
            padding: 0 10px;
          }
        '';
      };

      # Redshift doesn't work on Wayland, use Gammastep
      services.gammastep = {
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

      # Declarative Labwc Configuration
      xdg.configFile."labwc/rc.xml".text = ''
        <?xml version="1.0" ?>
        <labwc_config>
          <core>
            <decoration>server</decoration>
          </core>
          <theme>
            <name>Platinum9</name> <cornerRadius>0</cornerRadius>
            <font name="Sans" size="10" />
          </theme>
          <outputs>
            <output name="eDP-1">
              <scale>2</scale>
            </output>
          </outputs>
          <keyboard>
            <default />
            <!-- Bindings mimicking your XFCE setup -->
            <keybind key="A-Return"><action name="Execute" command="ghostty" /></keybind>
            <keybind key="A-e"><action name="Execute" command="pcmanfm-qt" /></keybind>
            <keybind key="A-c"><action name="Execute" command="google-chrome-stable" /></keybind>
            <keybind key="A-d"><action name="Execute" command="rofi -show drun" /></keybind>
            <keybind key="A-q"><action name="Close" /></keybind>
          </keyboard>
          <mouse>
            <default />
            <libinput>
              <device>
                <naturalScroll>yes</naturalScroll>
              </device>
            </libinput>
          </mouse>
        </labwc_config>
      '';

      # Environment variables for Wayland and HiDPI
      xdg.configFile."labwc/environment".text = ''
        GDK_BACKEND=wayland
        QT_QPA_PLATFORM=wayland
        CLUTTER_BACKEND=wayland
        SDL_VIDEODRIVER=wayland
        XDG_SESSION_TYPE=wayland
        XDG_CURRENT_DESKTOP=labwc
        MOZ_ENABLE_WAYLAND=1

        # Removed GDK_SCALE=2
        XCURSOR_SIZE=32
      '';

      # Autostart essential Wayland daemons
      xdg.configFile."labwc/autostart" = {
        executable = true;
        text = ''
          # Removed wlr-randr scaling script

          # Update DBus environment
          dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP

          # Initialize Keyring
          eval $(gnome-keyring-daemon --start --components=secrets)
          export SSH_AUTH_SOCK

          # Start Polkit agent
          ${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1 &

          waybar &
          pcmanfm-qt --desktop &
          wbg ${pkgs.nixos-artwork.wallpapers.binary-white.src} &
        '';
      };

      xdg.portal = {
        enable = true;
        extraPortals = [
          pkgs.xdg-desktop-portal-wlr
          pkgs.xdg-desktop-portal-gtk
        ];
        config.common.default = "*";
      };
    })
  ];
}
