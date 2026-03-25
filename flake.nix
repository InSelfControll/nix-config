{
  description = "Ofir's NixOS configurations";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";

  outputs = { self, nixpkgs }: let
    system = "x86_64-linux";
  in {

    nixosConfigurations = {

      home-desktop = nixpkgs.lib.nixosSystem {
        inherit system;
        modules = [
          ./modules/dev-setup.nix
          ./hosts/home-desktop.nix
          { nixos-setup.graphical = true; }
        ];
      };

      server = nixpkgs.lib.nixosSystem {
        inherit system;
        modules = [
          ./modules/dev-setup.nix
          ./hosts/server.nix
          { nixos-setup.graphical = false; }
        ];
      };

      iso = nixpkgs.lib.nixosSystem {
        inherit system;
        modules = [
          "${nixpkgs}/nixos/modules/installer/cd-dvd/installation-cd-graphical-calamares-plasma6.nix"
          ({ pkgs, ... }: {
            isoImage.isoName  = "nixos-ofir.iso";
            isoImage.volumeID = "NIXOS_OFIR";
            boot.loader.timeout = 8;
            nix.settings.experimental-features = [ "nix-command" "flakes" ];
            nixpkgs.config.allowUnfree = true;
            services.openssh.enable = true;
            users.users.root.initialPassword = "nixos";
          })
        ];
      };
    };

    packages.${system}.iso =
      self.nixosConfigurations.iso.config.system.build.isoImage;
  };
}
