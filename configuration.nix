{
  config,
  pkgs,
  lib,
  ...
}:
{
  sops = {
    defaultSopsFile = ./secrets.yaml;
    validateSopsFiles = false;

    # this is critical for ephemeral systems:
    # tell sops to look for the key on the persistent partition
    age.keyFile = "/persist/var/lib/sops-nix/key.txt";

    secrets.user-password = {
      neededForUsers = true; # required so it's available at login
    };
  };

  nix = {
    settings = {
      # Deduplicate storage (saves space by linking identical files)
      auto-optimise-store = true;
      # Allow the flake command to work
      experimental-features = [
        "nix-command"
        "flakes"
      ];
    };
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 7d";
    };
  };

  nixpkgs.config.allowUnfree = true;

  networking.networkmanager.enable = true;
  networking.hostName = "nixy";

  services.thermald.enable = true;

  services.power-profiles-daemon.enable = false;

  services.tlp = {
    enable = true;
    pd.enable = true;

    settings = {
      # Huawei MateBook specific thresholds (via huawei_wmi driver)
      START_CHARGE_THRESH_BAT0 = 75;
      STOP_CHARGE_THRESH_BAT0 = 80;

      # Intel Core Ultra 5 (Meteor Lake) Optimizations
      # These mimic what PPD would normally do, but through TLP
      CPU_SCALING_GOVERNOR_ON_AC = "performance";
      CPU_SCALING_GOVERNOR_ON_BAT = "powersave";

      CPU_ENERGY_PERF_POLICY_ON_AC = "performance";
      CPU_ENERGY_PERF_POLICY_ON_BAT = "balance_power";

      # Helps with Intel's modern "Meteor Lake" efficiency
      CPU_BOOST_ON_AC = 1;
      CPU_BOOST_ON_BAT = 0;
    };
  };

  # 3. Firmware (Crucial for Wi-Fi and GPU microcode)
  hardware.enableRedistributableFirmware = true;

  # 2. use the secret for your user
  users.users.alunity = {
    isNormalUser = true;
    extraGroups = [
      "wheel"
      "networkmanager"
      "video"
    ];
    # instead of hashedpassword, use hashedpasswordfile
    hashedPasswordFile = config.sops.secrets.user-password.path;
  };

  users.users.root.hashedPasswordFile = config.sops.secrets.user-password.path;

  # Enable hardware acceleration
  hardware.graphics = {
    enable = true;
    extraPackages = with pkgs; [
      intel-media-driver # For Broadwell and newer (Meteor Lake included)
      intel-vaapi-driver # VA-API for older software
      libvdpau-va-gl
      intel-compute-runtime # OpenCL for Arc Graphics
      vpl-gpu-rt # OneVPL for hardware video processing
    ];
  };

  services.xserver.enable = true;
  services.displayManager.gdm.enable = true;
  services.desktopManager.gnome.enable = true;
  services.libinput.enable = true; # For touchpads

  services.xserver.xkb = {
    layout = "gb";
    variant = "";
  };
  console.keyMap = "uk";

  security.sudo.extraConfig = ''
    		Defaults lecture=never
    	'';

  # critical for tmpfs: allow nixos to boot with a blank root
  fileSystems."/".neededForBoot = true;
  fileSystems."/persist".neededForBoot = true;

  # bootloader settings
  boot.loader.systemd-boot.enable = lib.mkForce false;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.systemd-boot.configurationLimit = 10;
  boot.loader.timeout = 0;

  boot.lanzaboote = {
    enable = true;
    pkiBundle = "/etc/secureboot"; # This folder MUST be persisted!
  };

  boot.initrd.luks.devices."crypted" = {
    preLVM = true;
    allowDiscards = true;
    # This is the magic line:
    crypttabExtraOpts = [ "tpm2-device=auto" ];
  };

  zramSwap.enable = true;

  environment.persistence."/persist" = {
    hideMounts = true;
    directories = [
      "/etc/secureboot"
      "/var/lib/sbctl" # The metadata database (Fixes the migrate error)
      "/var/log"
      "/var/lib/bluetooth"
      "/var/lib/nixos"
      "/var/lib/systemd/coredump"
      "/etc/NetworkManager/system-connections"
      "/var/lib/sops-nix"
      "/var/lib/gdm"
      "/var/lib/accounts-service"
      "/home/alunity"
    ];
    files = [
      "/etc/machine-id"
    ];
  };

  environment.systemPackages = with pkgs; [
    sbctl
    sops
    gnome-tweaks
    adw-gtk3
  ];

  fonts.packages = with pkgs; [
    noto-fonts
    noto-fonts-cjk-sans
    noto-fonts-cjk-serif
    noto-fonts-color-emoji
    liberation_ttf
    fira-code
    fira-code-symbols
    mplus-outline-fonts.githubRelease
    dina-font
    proggyfonts
    wqy_zenhei
  ];

  # It tells your system which fonts to prefer for specific types of text.
  fonts.fontconfig = {
    defaultFonts = {
      serif = [
        "Noto Serif"
        "Noto Serif CJK SC"
      ];
      sansSerif = [
        "Noto Sans"
        "Noto Sans CJK SC"
      ];
      monospace = [
        "JetBrains Mono"
        "Noto Sans Mono CJK SC"
      ];
      emoji = [ "Noto Color Emoji" ];
    };
  };

  programs.nix-ld.enable = true;

  services.kmonad = {
    enable = true;
    keyboards = {
      laptop-internal = {
        device = "/dev/input/by-path/platform-i8042-serio-0-event-kbd";

        config = builtins.readFile ./lap-keyboard.kbd;
      };
    };
  };

  time.timeZone = "Europe/London"; # Replace with your actual zone
  i18n.defaultLocale = "en_GB.UTF-8";
  i18n.supportedLocales = [
    "en_GB.UTF-8/UTF-8"
    "en_US.UTF-8/UTF-8"
  ];
  # services.automatic-timezoned.enable = true;
  # services.geoclue2.enable = true;

  services.printing = {
    enable = true;
    cups-pdf.enable = true;
  };

  system.stateVersion = "24.11"; # Ensure this matches your nixpkgs!
}
