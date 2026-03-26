{ config, pkgs, lib, modulesPath, self, ... }:

{
  imports = [
    (modulesPath + "/installer/cd-dvd/installation-cd-graphical-calamares-plasma6.nix")
    ./dev-setup.nix
  ];

  nixos-setup.graphical = true;

  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  nixpkgs.config.allowUnfree = true;

  isoImage.isoName  = "nixos-ofir.iso";
  isoImage.volumeID = "NIXOS_OFIR";
  isoImage.squashfsCompression = "zstd -Xcompression-level 3";

  services.openssh.enable = true;

  users.users.root.initialPassword = "nixos";
  users.users.nixos.initialPassword = "nixos";

  services.earlyoom.enable = true;

  environment.systemPackages = with pkgs; [
    git curl wget vim pciutils jq
  ];

  # 🔥 your service (now valid)
  systemd.services.bootstrap-system = {
    description = "Bootstrap NixOS from Git flake";
    wantedBy = [ "multi-user.target" ];
    after = [ "network-online.target" ];

    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };

    script = ''
      echo "Bootstrapping system..."
      nixos-rebuild switch \
        --flake github:InSelfControll/nix-config#home-desktop
    '';
  };
}
