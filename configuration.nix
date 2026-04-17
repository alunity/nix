# todo: split into system and home
{ config, pkgs, lib, ... }:
{
  sops = {
    defaultSopsFile = ./secrets.yaml;
    validateSopsFiles = false;
    
    # this is critical for ephemeral systems:
    # tell sops to look for the key on the persistent partition
    age.keyfile = "/persist/var/lib/sops-nix/key.txt";

    secrets.user-password = {
      neededforusers = true; # required so it's available at login
    };
  };

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
  
  services.thermald.enable = true;

  # 2. Power management (Better battery life)
  # NOTE: Don't use this if you plan to use 'tlp' - they conflict.
  services.power-profiles-daemon.enable = true; 

  # 3. Firmware (Crucial for Wi-Fi and GPU microcode)
  hardware.enableRedistributableFirmware = true;

  # 2. use the secret for your user
  users.users.alunity = {
    isNormalUser = true;
    extraGroups = [ "wheel" "networkmanager", "video" ];
    # instead of hashedpassword, use hashedpasswordfile
    hashedPasswordFile = config.sops.secrets.user-password.path;
  };

  # 3. System Services (GNOME)
  services.xserver.enable = true;
  services.xserver.displayManager.gdm.enable = true;
  services.xserver.desktopManager.gnome.enable = true;
  services.libinput.enable = true; # For touchpads


  # critical for tmpfs: allow nixos to boot with a blank root
  fileSystems."/".neededForBoot = true;

  # bootloader settings
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.cantouchefivariables = true;
  boot.loader.systemd-boot.configurationlimit = 10;
 
  zramswap.enable = true;

  environment.persistence."/persist" = {
    hidemounts = true;
    directories = [
      "/var/log"
      "/var/lib/bluetooth"
      "/var/lib/nixos"
      "/var/lib/systemd/coredump"
      "/etc/networkmanager/system-connections"
      "/var/lib/sops-nix"
      "/var/lib/gdm"
      "/var/lib/accounts-service"
      "/home/alunity"
    ];
    files = [
      "/etc/machine-id"
    ];
  };
  system.stateVersion = "24.11"; # Ensure this matches your nixpkgs!
}
