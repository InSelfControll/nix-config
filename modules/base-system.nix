{ lib, ... }: {
  boot.loader.grub.enable = true;
  boot.loader.grub.device = lib.mkDefault "/dev/vda";
  boot.loader.grub.useOSProber = false;

  system.stateVersion = "25.11";
}
