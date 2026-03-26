{ ... }: {
  # Let Calamares/nixos-generate-config handle the bootloader device.
  # Each host's hardware-configuration.nix already has the right value.
  boot.loader.grub.enable = true;
  boot.loader.grub.useOSProber = false;

  system.stateVersion = "25.11";
}
