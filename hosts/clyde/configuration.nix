{
  config,
  pkgs,
  lib,
  ...
}:
{
  imports = [
    ../../modules/sops.nix
    ../../modules/system/core.nix
    ../../modules/system/desktop.nix
    # ../../modules/system/virtualisation.nix
  ];

  sops.secrets.user-password = {
    neededForUsers = true;
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
  networking.hostName = "clyde";

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
      CPU_SCALING_GOVERNOR_ON_AC = "powersave";
      CPU_SCALING_GOVERNOR_ON_BAT = "powersave";

      CPU_ENERGY_PERF_POLICY_ON_AC = "balance_performance";
      CPU_ENERGY_PERF_POLICY_ON_BAT = "powersave";

      # Helps with Intel's modern "Meteor Lake" efficiency
      CPU_BOOST_ON_AC = 1;
      CPU_BOOST_ON_BAT = 1;

      PLATFORM_PROFILE_ON_AC = "balanced";
      PLATFORM_PROFILE_ON_BAT = "low-power";
    };
  };

  # 3. Firmware (Crucial for Wi-Fi and GPU microcode)
  hardware.enableRedistributableFirmware = true;

  # 2. use the secret for your user
  users.users.${config.my.core.username} = {
    isNormalUser = true;
    extraGroups = [
      "wheel"
      "networkmanager"
      "video"
      "scanner"
      "lp"
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

  my.desktop.gnome.enable = true;
  services.libinput.enable = true; # For touchpads
  services.libinput.touchpad.naturalScrolling = true;

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
      "/etc/ssh"
      "/var/lib/sbctl" # The metadata database (Fixes the migrate error)
      "/var/log"
      "/var/lib/bluetooth"
      "/var/lib/nixos"
      "/var/lib/systemd/coredump"
      "/etc/NetworkManager/system-connections"
      "/var/lib/sops-nix"
      "/var/lib/gdm"
      "/var/lib/accounts-service"
      "/var/lib/flatpak"
      "/var/lib/libvirt"
      "/var/lib/syncthing"
      "/var/lib/containers"
      {
        directory = "/home/${config.my.core.username}";
        user = config.my.core.username;
        group = "users"; # or config.users.users.${config.my.core.username}.group
        mode = "0700";
      }
    ];
    files = [
      "/etc/machine-id"
    ];
  };

  environment.systemPackages = with pkgs; [
    nixd
    nixfmt
    nix-tree

    sbctl
    sops

    gnome-tweaks
    adw-gtk3

    distrobox
  ];
  services.tailscale.enable = false;

  fonts.packages = with pkgs; [
    noto-fonts
    noto-fonts-cjk-sans
    noto-fonts-cjk-serif
    noto-fonts-color-emoji
    liberation_ttf
    nerd-fonts.caskaydia-cove
    fira-code
    fira-code-symbols
    mplus-outline-fonts.githubRelease
    dina-font
    proggyfonts
    wqy_zenhei
  ];

  security.rtkit.enable = true;

  # Prevent USB auto-suspend and clock drift on the KTMicro DAC
  boot.extraModprobeConfig = ''
    options snd-usb-audio implicit_fb=1
  '';

  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;

    # 2. Lock graph clock to 48kHz
    extraConfig.pipewire = {
      "10-clock-rates" = {
        "context.properties" = {
          "default.clock.rate" = 48000;
          "default.clock.allowed-rates" = [ 48000 ];
          "default.clock.quantum" = 1024;
          "default.clock.min-quantum" = 512;
          "default.clock.max-quantum" = 2048;
        };
      };
    };

    # 3. Hardware rules: 16-bit format + force hardware node to output [ FL FR ]
    wireplumber.extraConfig = {
      "50-chu2-dsp-hardware" = {
        "monitor.alsa.rules" = [
          {
            matches = [
              {
                "alsa.card_name" = "Chu2 DSP";
              }
              {
                "device.bus" = "usb";
              }
            ];
            actions = {
              update-props = {
                # 16-bit stability for KTMicro DSP chip
                "audio.format" = "S16LE";
                "audio.rate" = 48000;
                "audio.allowed-rates" = [ 48000 ];

                # Hardware buffer sizing & scheduling
                "api.alsa.period-size" = 1024;
                "api.alsa.headroom" = 1024;
                "api.alsa.disable-tsched" = true;
                "api.alsa.disable-mmap" = false;
                "resample.quality" = 4;

                # FORCE single mono capture port to duplicate to stereo (FL + FR)
                "audio.position" = [
                  "FL"
                  "FR"
                ];
              };
            };
          }
        ];
      };
    };
  };

  # It tells your system which fonts to prefer for specific types of text.
  fonts.fontconfig = {
    enable = true;
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

        config = builtins.readFile ../../config/lap-keyboard.kbd;
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
  services.geoclue2.enable = true;

  services.avahi = {
    enable = true;
    nssmdns4 = true;
    openFirewall = true;
  };

  services.printing = {
    enable = true;
  };

  hardware.sane = {
    enable = true;
    extraBackends = [ pkgs.sane-airscan ];
  };

  services.udev.packages = [ pkgs.sane-airscan ];
  services.flatpak.enable = true;

  services.syncthing = {
    enable = true;
    user = config.my.core.username;
    group = "users";
    dataDir = "/home/${config.my.core.username}"; # Base directory for synced paths
    configDir = "/home/${config.my.core.username}/.config/syncthing";

    # 2. Open firewall ports (22000 TCP/UDP for sync traffic, 21027 UDP for local discovery)
    openDefaultPorts = true;
  };

  virtualisation.podman = {
    enable = true;
    dockerCompat = true;
    defaultNetwork.settings.dns_enabled = true;
  };

  system.stateVersion = "26.05"; # Ensure this matches your nixpkgs!
}
