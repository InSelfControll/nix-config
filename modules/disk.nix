# Declares the disk layout using disko — replaces manual partitioning
{ lib, ... }: {
  disko.devices = {
    disk.main = {
      type = "disk";
      device = lib.mkDefault "/dev/vda"; # overridden per host if needed
      content = {
        type = "gpt";
        partitions = {
          ESP = {
            size = "512M";
            type = "EF00";
            content = {
              type = "filesystem";
              format = "vfat";
              mountpoint = "/boot";
            };
          };
          root = {
            size = "100%";
            content = {
              type = "filesystem";
              format = "ext4";
              mountpoint = "/";
            };
          };
        };
      };
    };
  };
}
