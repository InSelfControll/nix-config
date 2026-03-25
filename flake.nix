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
          ./modules/dev-setup.nix
          { nixos-setup.graphical = true; }

          ({ config, pkgs, lib, ... }: {
            isoImage.isoName  = "nixos-ofir.iso";
            isoImage.volumeID = "NIXOS_OFIR";
            boot.loader.timeout = 8;

            nix.settings.experimental-features = [ "nix-command" "flakes" ];
            nixpkgs.config.allowUnfree = true;

            services.openssh.enable = true;
            users.users.root.initialPassword = "nixos";

            # Ship the repo inside the ISO at /etc/nixos-config
            isoImage.contents = [{
              source = ./.;
              target = "/etc/nixos-config";
            }];

            # Install script — sits on the desktop, user runs it instead of
            # (or after) Calamares. Does partitioning + flake install in one go.
            environment.etc."install-system.sh" = {
              mode = "0755";
              text = ''
                #!/usr/bin/env bash
                set -e
                export NIX_CONFIG="experimental-features = nix-command flakes"

                echo "======================================"
                echo "  Ofir NixOS Flake Installer"
                echo "======================================"
                echo ""

                # List available disks
                echo "Available disks:"
                lsblk -d -o NAME,SIZE,MODEL | grep -v loop
                echo ""
                read -rp "Target disk (e.g. vda, sda, nvme0n1): " DISK
                DISK="/dev/$DISK"

                read -rp "Install type — [g]raphical KDE or [m]inimal? " TYPE
                HOST="home-desktop"
                [[ "$TYPE" == "m"* ]] && HOST="server"

                echo ""
                echo "WARNING: $DISK will be wiped. Press Enter to continue or Ctrl+C to abort."
                read

                # Partition: ESP + root (UEFI)
                parted "$DISK" -- mklabel gpt
                parted "$DISK" -- mkpart ESP fat32 1MB 512MB
                parted "$DISK" -- set 1 esp on
                parted "$DISK" -- mkpart primary 512MB 100%

                # Detect partition naming (nvme uses p1/p2, others use 1/2)
                if [[ "$DISK" == *"nvme"* ]]; then
                  PART1="${DISK}p1"
                  PART2="${DISK}p2"
                else
                  PART1="${DISK}1"
                  PART2="${DISK}2"
                fi

                mkfs.fat  -F32 "$PART1"
                mkfs.ext4 -L nixos "$PART2"

                mount "$PART2" /mnt
                mkdir -p /mnt/boot
                mount "$PART1" /mnt/boot

                # Copy flake into target
                mkdir -p /mnt/etc/nixos
                cp -r /etc/nixos-config/. /mnt/etc/nixos/
                chmod -R u+w /mnt/etc/nixos

                # Generate hardware config for this machine
                nixos-generate-config --root /mnt
                cp /mnt/etc/nixos/hardware-configuration.nix \
                   /mnt/etc/nixos/hosts/target-hardware.nix

                # Write a minimal host file for this machine
                cat > /mnt/etc/nixos/hosts/target.nix << EOF
{ ... }: {
  imports = [ ./target-hardware.nix ];
  networking.hostName = "nixos";
}
EOF

                # Add "target" to flake if not present
                if ! grep -q '"target"' /mnt/etc/nixos/flake.nix; then
                  sed -i "s|nixosConfigurations = {|nixosConfigurations = {\n\
      target = nixpkgs.lib.nixosSystem {\n\
        system = \"x86_64-linux\";\n\
        modules = [\n\
          ./modules/dev-setup.nix\n\
          ./hosts/target.nix\n\
          { nixos-setup.graphical = $( [[ "$HOST" == "home-desktop" ]] \&\& echo true \|\| echo false ); }\n\
        ];\n\
      };\n|" /mnt/etc/nixos/flake.nix
                fi

                # Install!
                nixos-install --root /mnt --flake /mnt/etc/nixos#target --no-root-passwd

                echo ""
                echo "======================================"
                echo "  Installation complete!"
                echo "  Remove the ISO and reboot."
                echo "======================================"
              '';
            };

            # Desktop shortcut for the install script
            environment.etc."skel/Desktop/Install NixOS.desktop".text = ''
              [Desktop Entry]
              Name=Install NixOS (Flake)
              Comment=Run the flake-based installer
              Exec=konsole -e sudo /etc/install-system.sh
              Icon=system-software-install
              Terminal=false
              Type=Application
            '';
          })
        ];
      };
    };

    packages.${system}.iso =
      self.nixosConfigurations.iso.config.system.build.isoImage;
  };
}
