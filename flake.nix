{
  description = "Ofir's NixOS configurations";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";

  outputs = { self, nixpkgs }: let
    system = "x86_64-linux";
  in {

    nixosConfigurations = {

      # ── Installed hosts (nixos-rebuild / nixos-anywhere) ─────────────────
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

      # ── Unified ISO ───────────────────────────────────────────────────────
      iso = nixpkgs.lib.nixosSystem {
        inherit system;
        modules = [
          "${nixpkgs}/nixos/modules/installer/cd-dvd/installation-cd-graphical-calamares-plasma6.nix"
          ./modules/dev-setup.nix
          { nixos-setup.graphical = true; }

          ({ config, pkgs, lib, ... }: {
            isoImage.isoName  = "nixos-ofir.iso";
            isoImage.volumeID = "NIXOS_OFIR";
            boot.loader.timeout = 8;

            # Flakes must be enabled on the live ISO so nixos-install works
            nix.settings.experimental-features = [ "nix-command" "flakes" ];
            nixpkgs.config.allowUnfree = true;

            services.openssh.enable = true;
            users.users.root.initialPassword = "nixos";

            # ── Embed the entire flake repo into the ISO ──────────────────
            # Calamares calls nixos-install which needs to evaluate a flake.
            # We ship the repo at /etc/nixos-config on the live ISO, then a
            # pre-install hook copies it into /mnt/etc/nixos/ so the installed
            # system has the flake and every future nixos-rebuild works too.
            isoImage.contents = [
              {
                source = ./.;          # the whole repo
                target = "/etc/nixos-config";
              }
            ];

            # ── Calamares pre-install hook ────────────────────────────────
            # Runs just before nixos-install. Copies the flake into /mnt,
            # generates hardware-configuration.nix for the target machine,
            # then rewrites /mnt/etc/nixos/hosts/target.nix with the real
            # hardware config. Calamares then calls nixos-install --flake.
            environment.etc."calamares/modules/nixos.conf".text = ''
              ---
              preInstallCommands: |
                set -e
                cp -r /etc/nixos-config /mnt/etc/nixos
                chmod -R u+w /mnt/etc/nixos
                nixos-generate-config --root /mnt
                cp /mnt/etc/nixos/hardware-configuration.nix \
                   /mnt/etc/nixos/hosts/target-hardware.nix
                # Patch flake.nix to add a "target" host using the generated hardware
                if ! grep -q '"target"' /mnt/etc/nixos/flake.nix; then
                  sed -i 's|nixosConfigurations = {|nixosConfigurations = {\n\
                    target = nixpkgs.lib.nixosSystem {\n\
                      system = "x86_64-linux";\n\
                      modules = [\n\
                        ./modules/dev-setup.nix\n\
                        ./hosts/target-hardware.nix\n\
                        { nixos-setup.graphical = true; }\n\
                      ];\n\
                    };\n|' /mnt/etc/nixos/flake.nix
                fi
              nixosConfigFile: "/mnt/etc/nixos/flake.nix#target"
            '';
          })
        ];
      };
    };

    packages.${system}.iso =
      self.nixosConfigurations.iso.config.system.build.isoImage;
  };
}

