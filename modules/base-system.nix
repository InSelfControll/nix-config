# modules/base-system.nix
{
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  fileSystems."/" = {
    device = "/dev/sda1";
    fsType = "ext4";
  };

  system.stateVersion = "25.05";
}
