{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.my.desktop; # A shorthand to access our custom options
in
{
  # 1. Define your custom options
  options.my.desktop = {
    gnome.enable = lib.mkEnableOption "Enable GNOME Desktop Environment";
    xfce.enable = lib.mkEnableOption "Enable XFCE Desktop Environment";
    labwc.enable = lib.mkEnableOption "Enable Labwc Wayland Compositor"; # New option
  };

  # 2. Map those options to actual system configuration
  config = lib.mkMerge [
    # --- GNOME Configuration ---
    (lib.mkIf cfg.gnome.enable {
      services.xserver.enable = true;
      services.displayManager.gdm.enable = true;
      services.desktopManager.gnome.enable = true;
      environment.sessionVariables.NIXOS_OZONE_WL = "1";
    })

    # --- XFCE Configuration ---
    (lib.mkIf cfg.xfce.enable {
      services.xserver.enable = true;
      services.displayManager.defaultSession = "xfce";
      services.xserver.displayManager.lightdm = {
        enable = true;
        greeters.mini = {
          enable = true;
          user = "alunity"; # It will just prompt for your password
          extraConfig = ''
            [greeter]
            show-password-label = false
          '';
        };
      };
      services.xserver.desktopManager.xfce.enable = true;

      hardware.bluetooth.enable = true;
      services.blueman.enable = true;

      # Power management optimizations for XFCE (Fanless-style throttling)
      services.upower.enable = true;
      services.tlp.settings = {
        # Disable CPU Boost completely
        CPU_BOOST_ON_AC = lib.mkForce 0;
        CPU_BOOST_ON_BAT = lib.mkForce 0;

        # Hard cap the maximum performance (Frequency Ceiling)
        # 30% on AC, 20% on Battery - keeps the laptop cool and fan-silent
        CPU_MAX_PERF_ON_AC = lib.mkForce 30;
        CPU_MAX_PERF_ON_BAT = lib.mkForce 20;

        # Force aggressive power saving energy policies
        CPU_ENERGY_PERF_POLICY_ON_AC = lib.mkForce "power";
        CPU_ENERGY_PERF_POLICY_ON_BAT = lib.mkForce "power";

        # Lower GPU clocks to reduce heat from the graphics chip
        INTEL_GPU_MIN_FREQ_ON_AC = lib.mkForce 300;
        INTEL_GPU_MAX_FREQ_ON_AC = lib.mkForce 600;
        INTEL_GPU_MIN_FREQ_ON_BAT = lib.mkForce 300;
        INTEL_GPU_MAX_FREQ_ON_BAT = lib.mkForce 400;
      };

      # Thermald helps with passive cooling (throttling instead of fans)
      services.thermald.enable = true;
      services.cpupower-gui.enable = true;
    })

    (lib.mkIf cfg.labwc.enable {
      programs.labwc.enable = true;

      services.gnome.gnome-keyring.enable = true;
      security.pam.services.greetd.enableGnomeKeyring = true;

      services.greetd = {
        enable = true;
        settings = {
          default_session = {
            command = "${pkgs.tuigreet}/bin/tuigreet --time --cmd 'fish --login -c labwc'";
            user = "alunity";
          };
        };
      };

      services.upower.enable = true;
      services.tlp.settings = {
        CPU_BOOST_ON_AC = lib.mkForce 0;
        CPU_BOOST_ON_BAT = lib.mkForce 0;
        CPU_MAX_PERF_ON_AC = lib.mkForce 30;
        CPU_MAX_PERF_ON_BAT = lib.mkForce 20;
        CPU_ENERGY_PERF_POLICY_ON_AC = lib.mkForce "power";
        CPU_ENERGY_PERF_POLICY_ON_BAT = lib.mkForce "power";
        INTEL_GPU_MIN_FREQ_ON_AC = lib.mkForce 300;
        INTEL_GPU_MAX_FREQ_ON_AC = lib.mkForce 600;
        INTEL_GPU_MIN_FREQ_ON_BAT = lib.mkForce 300;
        INTEL_GPU_MAX_FREQ_ON_BAT = lib.mkForce 400;
      };
      services.thermald.enable = true;
      services.cpupower-gui.enable = true;

      # Basic Wayland hardware support
      hardware.bluetooth.enable = true;
      services.blueman.enable = true;
      hardware.graphics.enable = true;
    })
  ];
}
