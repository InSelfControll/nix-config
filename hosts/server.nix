{ ... }: {
  imports = [ ./hardware-configuration.nix ];
  networking.hostName = "server";
}

