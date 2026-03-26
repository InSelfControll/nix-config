{ ... }: {
  networking.hostName = "server";
  users.users.root.initialPassword = "nixos";
}
