{ ... }: {
  imports = [ ./hardware-configuration.nix ];
  networking.hostName = "server";
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
}

