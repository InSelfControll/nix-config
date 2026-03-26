{ ... }: {
  imports = [ ./hardware-configuration.nix ];
  networking.hostName = "home-desktop";
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
}
