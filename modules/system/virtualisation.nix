# /etc/nixos/virtualisation.nix

{ config, pkgs, ... }:

let
  # The hook script that manages the GPU state
  qemu-hook = pkgs.writeShellScript "qemu-hook" ''
    GUEST_NAME="$1"
    HOOK_NAME="$2"
    STATE_NAME="$3"

    # Replace "win10" with the exact name of your VM in virt-manager
    if [ "$GUEST_NAME" == "win10" ]; then
      
      if [ "$HOOK_NAME" == "prepare" ] && [ "$STATE_NAME" == "begin" ]; then
        # 1. Stop GNOME/Display Manager
        systemctl stop display-manager.service
        
        # 2. Unbind VTconsoles
        echo 0 > /sys/class/vtconsole/vtcon0/bind || true
        echo 0 > /sys/class/vtconsole/vtcon1/bind || true
        
        # 3. Unbind EFI Framebuffer
        echo efi-framebuffer.0 > /sys/bus/platform/drivers/efi-framebuffer/unbind || true
        
        # 4. Unload Intel drivers (Meteor Lake uses xe or i915)
        modprobe -r xe || true
        modprobe -r i915 || true
        modprobe -r intel_gtt || true
        modprobe -r drm_kms_helper || true
        
        # 5. Load VFIO
        modprobe vfio_pci
        modprobe vfio_iommu_type1
        
      elif [ "$HOOK_NAME" == "release" ] && [ "$STATE_NAME" == "end" ]; then
        # 1. Unload VFIO
        modprobe -r vfio_pci
        modprobe -r vfio_iommu_type1
        
        # 2. Reload Intel drivers
        modprobe xe || true
        modprobe i915 || true
        modprobe drm_kms_helper || true
        modprobe intel_gtt || true
        
        # 3. Rebind VTconsoles
        echo 1 > /sys/class/vtconsole/vtcon0/bind || true
        echo 1 > /sys/class/vtconsole/vtcon1/bind || true
        
        # 4. Rebind EFI Framebuffer
        echo efi-framebuffer.0 > /sys/bus/platform/drivers/efi-framebuffer/bind || true
        
        # 5. Restart GNOME/Display Manager
        systemctl start display-manager.service
      fi
    fi
  '';
in
{
  # Enable dconf (required for virt-manager to save settings)
  programs.dconf.enable = true;

  # Add virt-manager for a GUI
  programs.virt-manager.enable = true;

  # Core virtualisation services
  virtualisation.libvirtd = {
    enable = true;
    qemu = {
      package = pkgs.qemu_kvm;
      runAsRoot = true;
      swtpm.enable = true;
    };
  };

  # IOMMU and VFIO Kernel parameters specific to your Intel Ultra CPU
  boot.kernelParams = [
    "intel_iommu=on"
    "iommu=pt"
  ];

  # Load the necessary VFIO kernel modules
  boot.kernelModules = [
    "kvm-intel"
    "vfio_pci"
    "vfio"
    "vfio_iommu_type1"
    "vfio_virqfd"
  ];

  # Add your specific user to the necessary groups
  users.users.alunity = {
    extraGroups = [
      "libvirtd"
      "kvm"
    ];
  };

  # Link the script to the location Libvirt expects
  systemd.tmpfiles.rules = [
    "L+ /var/lib/libvirt/hooks/qemu - - - - ${qemu-hook}"
  ];

  services.openssh = {
    enable = true;

    hostKeys = [
      {
        path = "/etc/ssh/ssh_host_ed25519_key";
        type = "ed25519";
      }
    ];

    # Only listen on the VM bridge and internal localhost
    listenAddresses = [
      {
        addr = "192.168.122.1";
        port = 22;
      }
      {
        addr = "127.0.0.1";
        port = 22;
      }
    ];

    settings = {
      # Disallow root login for security. You will log in as 'alunity'
      PermitRootLogin = "no";

      # Set to 'false' if you have SSH keys set up on your phone.
      # If you just want to use your user password for now, leave it 'true'.
      PasswordAuthentication = true;
    };
  };

  services.logind = {
    # Force the host to completely ignore the lid closing if plugged into a dock/power
    settings.Login = {
      HandleLidSwitch = "suspend";
      HandleLidSwitchExternalPower = "ignore";
    };
  };

  # Explicitly open port 22 in the firewall
  networking.firewall.allowedTCPPorts = [ 22 ];

  # 1. Create a permanent symlink at /dev/input/kmonad-kbd
  services.udev.extraRules = ''
    KERNEL=="event*", ATTRS{name}=="My KMonad output", SYMLINK+="input/kmonad-kbd"
  '';

  # 2. Whitelist that new permanent path in QEMU
  virtualisation.libvirtd.qemu.verbatimConfig = ''
    cgroup_device_acl = [
      "/dev/null", "/dev/full", "/dev/zero",
      "/dev/random", "/dev/urandom",
      "/dev/ptmx", "/dev/kvm", "/dev/kqemu",
      "/dev/rtc", "/dev/hpet",
      "/dev/input/by-path/pci-0000:00:15.0-platform-i2c_designware.0-event-mouse",
      "/dev/input/kmonad-kbd"
    ]
  '';
}
