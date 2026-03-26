{ pkgs, modulesPath, ... }: {
  imports = [
    (modulesPath + "/installer/cd-dvd/installation-cd-graphical-calamares-plasma6.nix")
  ];

  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  nixpkgs.config.allowUnfree = true;

  isoImage.volumeID = "NIXOS_OFIR";
  isoImage.squashfsCompression = "zstd -Xcompression-level 3";

  services.openssh.enable = true;
  services.earlyoom.enable = true;

  environment.systemPackages = with pkgs; [ git curl wget vim pciutils jq ];
}
