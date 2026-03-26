{ ... }: {
  networking.hostName = "home-desktop";
  users.users.root.initialPassword = "nixos";

  # Set this to whatever lsblk shows as your disk
  boot.loader.grub.device = "/dev/vda";
}
