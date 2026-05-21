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
    })
  ];
}
