{
  description = "Ofir's NixOS configurations";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
    disko.url   = "github:nix-community/disko";
    disko.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { self, nixpkgs, disko }: let
    system = "x86_64-linux";
  in {

    nixosConfigurations = {

      # Apply this to an existing NixOS install:
      # sudo nixos-rebuild switch --flake github:InSelfControll/nix-config#home-desktop --no-write-lock-file --refresh
      home-desktop = nixpkgs.lib.nixosSystem {
        inherit system;
        modules = [
          ./modules/base-system.nix
          ./modules/dev-setup.nix
          ./modules/core-tools.nix
          ./modules/desktop-tools.nix
          ./hosts/home-desktop.nix
        ];
      };

      server = nixpkgs.lib.nixosSystem {
        inherit system;
        modules = [
          ./modules/base-system.nix
          ./modules/dev-setup.nix
          ./modules/core-tools.nix
          ./modules/server-tools.nix
          ./hosts/server.nix
        ];
      };

      # Fresh install via nixos-anywhere (includes disko for partitioning)
      home-desktop-install = nixpkgs.lib.nixosSystem {
        inherit system;
        modules = [
          disko.nixosModules.disko
          ./modules/disk.nix
          ./modules/base-system.nix
          ./modules/dev-setup.nix
          ./modules/core-tools.nix
          ./modules/desktop-tools.nix
          ./hosts/home-desktop.nix
        ];
      };

      server-install = nixpkgs.lib.nixosSystem {
        inherit system;
        modules = [
          disko.nixosModules.disko
          ./modules/disk.nix
          ./modules/base-system.nix
          ./modules/dev-setup.nix
          ./modules/core-tools.nix
          ./modules/server-tools.nix
          ./hosts/server.nix
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
