{ lib, ... }: {
  # Use GRUB in BIOS mode — works on both BIOS and UEFI VMs
  boot.loader.grub = {
    enable = true;
    device = lib.mkDefault "nodev";
    efiSupport = lib.mkDefault true;
    efiInstallAsRemovable = lib.mkDefault true;
    useOSProber = false;
  };
  boot.loader.efi.canTouchEfiVariables = lib.mkDefault false;

  system.stateVersion = "25.11";
}
