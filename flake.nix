#!/usr/bin/env bash
# Run once after a fresh NixOS install to apply your flake config.
# Usage: bash apply-config.sh
set -e

REPO="https://github.com/inselfcontroll/nixos-config"   # <-- change to your repo URL
CONFIG_DIR="/etc/nixos-config"

echo "======================================"
echo "  Applying Ofir's NixOS config"
echo "======================================"

# Enable flakes if not already enabled
mkdir -p /etc/nix
grep -qxF 'experimental-features = nix-command flakes' /etc/nix/nix.conf 2>/dev/null || \
  echo 'experimental-features = nix-command flakes' >> /etc/nix/nix.conf

# Clone the config repo
if [ ! -d "$CONFIG_DIR" ]; then
  git clone "$REPO" "$CONFIG_DIR"
else
  git -C "$CONFIG_DIR" pull
fi

# Copy this machine's hardware config into the repo
cp /etc/nixos/hardware-configuration.nix "$CONFIG_DIR/hosts/$(hostname)-hardware.nix"

# Write a host file for this machine if it doesn't exist
HOST_FILE="$CONFIG_DIR/hosts/$(hostname).nix"
if [ ! -f "$HOST_FILE" ]; then
  cat > "$HOST_FILE" << HOSTEOF
{ ... }: {
  imports = [ ./$(hostname)-hardware.nix ];
  networking.hostName = "$(hostname)";
}
HOSTEOF
fi

# Add this host to flake.nix if not already there
HOSTNAME=$(hostname)
if ! grep -q "\"$HOSTNAME\"" "$CONFIG_DIR/flake.nix"; then
  read -rp "Install type — [g]raphical KDE or [m]inimal? " ITYPE
  GRAPHICAL="true"
  [[ "$ITYPE" == "m"* ]] && GRAPHICAL="false"

  sed -i "s|nixosConfigurations = {|nixosConfigurations = {\n\
      $HOSTNAME = nixpkgs.lib.nixosSystem {\n\
        system = \"x86_64-linux\";\n\
        modules = [\n\
          ./modules/dev-setup.nix\n\
          ./hosts/$HOSTNAME.nix\n\
          { nixos-setup.graphical = $GRAPHICAL; }\n\
        ];\n\
      };\n|" "$CONFIG_DIR/flake.nix"
fi

# Switch to the new config
nixos-rebuild switch --flake "$CONFIG_DIR#$HOSTNAME"

echo ""
echo "======================================"
echo "  Done! Your config is applied."
echo "  Re-login to trigger the setup dialog."
echo "======================================"
