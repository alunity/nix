{
  disko.devices = {
    disk = {
      main = {
        type = "disk";
        device = "/dev/nvme0n1"; # <-- CHANGE THIS to your actual disk
        content = {
          type = "gpt";
          partitions = {
            ESP = {
              size = "1G";
              type = "EF00";
              content = {
                type = "filesystem";
                format = "vfat";
                mountpoint = "/boot";
              };
            };
            luks = {
              size = "100%";
              content = {
                type = "luks";
                name = "crypted";
                # Comment out keyFile to use a manual password during install
                settings.keyFile = "/tmp/secret.key"; 
                content = {
                  type = "btrfs";
                  extraArgs = [ "-f" ];
                  subvolumes = {
                    # We don't mount / here. We leave it for the tmpfs in the OS config.
                    "/root" = {
                      mountpoint = "/partition-root"; # Mount it somewhere else just to have it
                    };
                    "/persist" = {
                      mountpoint = "/persist";
                      mountOptions = [ "compress=zstd" "noatime" ];
                    };
                    "/nix" = {
                      mountpoint = "/nix";
                      mountOptions = [ "compress=zstd" "noatime" ];
                    };
                    "/swap" = {
                      mountpoint = "/.swapvol";
                      swap.swapfile.size = "16G"; # <-- MUCH BETTER
                    };
                  };
                };
              };
            };
          };
        };
      };
    };
  };
}
