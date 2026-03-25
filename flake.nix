# flake.nix
{
  description = "Ofir's NixOS — unified ISO (KDE + minimal in one image)";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";

  outputs = { self, nixpkgs }: let
    system = "x86_64-linux";
  in {

    # ── Installed host configs (nixos-rebuild / nixos-anywhere) ───────────
    nixosConfigurations = {
      home-desktop = nixpkgs.lib.nixosSystem {
        inherit system;
        modules = [ ./modules/dev-setup.nix ./hosts/home-desktop.nix
                    { nixos-setup.graphical = true; } ];
      };
      server = nixpkgs.lib.nixosSystem {
        inherit system;
        modules = [ ./modules/dev-setup.nix ./hosts/server.nix ];
      };

      # ── Unified ISO ─────────────────────────────────────────────────────
      # Builds one ISO with two boot-menu entries.
      # The KDE entry loads the full Plasma + Calamares live environment.
      # The minimal entry drops straight to a console with SSH enabled.
      iso = nixpkgs.lib.nixosSystem {
        inherit system;
        modules = [
          # Base: KDE + Calamares live environment (superset of minimal)
          "${nixpkgs}/nixos/modules/installer/cd-dvd/installation-cd-graphical-calamares-plasma6.nix"
          ./modules/dev-setup.nix
          { nixos-setup.graphical = true; }

          # ── Unified ISO customisation ──────────────────────────────────
          ({ config, pkgs, lib, ... }: {

            isoImage.isoName = "nixos-ofir.iso";
            isoImage.volumeID = "NIXOS_OFIR";

            # Include SSH keys so nixos-anywhere can reach the minimal session
            services.openssh.enable = true;
            users.users.root.initialPassword = "nixos"; # change after install

            # Extra boot entries injected into the systemd-boot menu.
            # The KDE entry already exists from the Calamares import above;
            # we add a second entry for the minimal console session.
            boot.loader.systemd-boot.extraEntries = {
              "nixos-minimal.conf" = ''
                title   NixOS — Minimal console
                linux   /boot/bzImage
                initrd  /boot/initrd
                options init=/nix/var/nix/profiles/system/init ${config.boot.kernelParams} systemd.unit=multi-user.target nomodeset
              '';
            };

            # Give the default KDE entry a clear label in the menu
            isoImage.grubTheme = null;
            #boot.loader.timeout = 8;

            # A small script on the live ISO that explains the two options
            # when the user lands in the KDE session
            environment.etc."nixos-ofir-readme.txt".text = ''
              ╔══════════════════════════════════════════════╗
              ║        Ofir's NixOS Unified ISO              ║
              ╠══════════════════════════════════════════════╣
              ║  KDE entry   → Calamares graphical install   ║
              ║  Minimal entry → SSH console (port 22)       ║
              ║                  root password: nixos        ║
              ║                  use nixos-anywhere or       ║
              ║                  nixos-install manually      ║
              ╚══════════════════════════════════════════════╝
            '';
          })
        ];
      };
    };

    # ── Build alias ────────────────────────────────────────────────────────
    # nix build .#iso  →  result/iso/nixos-ofir.iso
    packages.${system}.iso =
      self.nixosConfigurations.iso.config.system.build.isoImage;
  };
}

