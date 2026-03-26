{
  description = "Ofir's NixOS configurations";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";

  outputs = { self, nixpkgs }: let
    system = "x86_64-linux";
  in 
  {

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
        modules = [ ./modules/iso.nix ];
      };

    };

    packages.${system}.iso =
      self.nixosConfigurations.iso.config.system.build.isoImage;
  };
}

