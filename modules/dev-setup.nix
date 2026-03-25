{ config, pkgs, lib, modulesPath, ... }:

{
  options.nixos-setup.graphical = lib.mkOption {
    type    = lib.types.bool;
    default = false;
    description = "Enable KDE Plasma + Calamares graphical installer.";
  };

  config = let
    isGraphical = config.nixos-setup.graphical;
  in {

    imports = lib.optional isGraphical
      "${modulesPath}/installer/cd-dvd/installation-cd-graphical-calamares-plasma6.nix";

    system.stateVersion = "25.11";
    nixpkgs.config.allowUnfree = true;

    services.openssh = {
      enable = true;
      settings.PermitRootLogin = "yes";
    };

    environment.plasma6.excludePackages = lib.optionals isGraphical
      (with pkgs.kdePackages; [
        kate elisa okular gwenview spectacle plasma-browser-integration
      ]);

    programs.nix-ld = {
      enable = true;
      libraries = with pkgs; [
        stdenv.cc.cc zlib openssl icu libunwind
        xorg.libX11 xorg.libXcursor xorg.libXrandr xorg.libXcomposite
        alsa-lib libglvnd
      ];
    };

    environment.systemPackages = with pkgs;
      [ git curl wget vim pciutils jq openssh appimage-run bun jdk21 ]
      ++ lib.optionals isGraphical [ zenity ];

    system.activationScripts.setupSkel = {
      deps = [ "etc" ];
      text = ''
        mkdir -p /etc/skel/.nixos-features

        cat > /etc/skel/.first_run_gui.sh << 'SCRIPT'
#!/usr/bin/env bash
if [ -f ~/.setup_done ]; then exit 0; fi

mkdir -p ~/.nixos-features ~/Applications

HAS_GUI=false
[ -n "$DISPLAY" ] || [ -n "$WAYLAND_DISPLAY" ] && HAS_GUI=true

CHOICES=""

if $HAS_GUI; then
  CHOICES=$(zenity --list --checklist \
    --title="NixOS Developer Setup" \
    --width=440 --height=360 \
    --column="Install" --column="Stack" \
    TRUE  "Web (Node 22.21)" \
    TRUE  "AbacusAI CLI" \
    TRUE  "Cursor AppImage" \
    FALSE "Warp terminal" \
    FALSE "Mobile (JDK21 / Expo)" \
    --separator="|") || exit 0
else
  echo "=== NixOS Developer Setup (headless) ==="
  echo "No display — Cursor and Warp will be skipped."
  echo ""
  read -rp "Install Web stack (Node 22.21)? [Y/n] " ans
  [[ "$ans" =~ ^[Nn] ]] || CHOICES+="|Web (Node 22.21)"
  read -rp "Install AbacusAI CLI? [Y/n] " ans
  [[ "$ans" =~ ^[Nn] ]] || CHOICES+="|AbacusAI CLI"
  read -rp "Install Mobile (JDK21 / Expo)? [y/N] " ans
  [[ "$ans" =~ ^[Yy] ]] && CHOICES+="|Mobile (JDK21 / Expo)"
fi

[[ "$CHOICES" == *"Web"*      ]] && touch ~/.nixos-features/web
[[ "$CHOICES" == *"AbacusAI"* ]] && touch ~/.nixos-features/ai
[[ "$CHOICES" == *"Cursor"*   ]] && touch ~/.nixos-features/cursor
[[ "$CHOICES" == *"Warp"*     ]] && touch ~/.nixos-features/warp
[[ "$CHOICES" == *"Mobile"*   ]] && touch ~/.nixos-features/mobile

if [[ "$CHOICES" == *"Web"* ]]; then
  echo "==> Installing NVM + Node 22.21..."
  export NVM_DIR="$HOME/.nvm"
  curl -fsSo- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash
  [ -s "$NVM_DIR/nvm.sh" ] && source "$NVM_DIR/nvm.sh"
  nvm install 22.21 && nvm alias default 22.21
fi

if [[ "$CHOICES" == *"AbacusAI"* ]]; then
  echo "==> Installing AbacusAI CLI..."
  mkdir -p ~/.abacusai_tool
  cd ~/.abacusai_tool && bun install @abacus-ai/cli
fi

if $HAS_GUI; then
  if [[ "$CHOICES" == *"Cursor"* ]]; then
    echo "==> Downloading Cursor..."
    CURSOR_URL=$(curl -fsSL \
      "https://www.cursor.com/api/download?platform=linux-x64&releaseTrack=stable" \
      | jq -r '.downloadUrl')
    curl -fSL "$CURSOR_URL" -o ~/Applications/cursor.AppImage
    chmod +x ~/Applications/cursor.AppImage
  fi

  if [[ "$CHOICES" == *"Warp"* ]]; then
    echo "==> Downloading Warp..."
    WARP_URL="https://releases.warp.dev/stable/v0.2025.03.18.08.02.stable_00/warp-terminal_0.2025.03.18.08.02.stable.00_amd64.deb"
    curl -fSL "$WARP_URL" -o /tmp/warp.deb
    cd /tmp && ar x warp.deb && tar -xf data.tar.* ./usr/bin/warp-terminal
    mv /tmp/usr/bin/warp-terminal ~/Applications/warp
    chmod +x ~/Applications/warp
    rm -f /tmp/warp.deb /tmp/data.tar.* /tmp/control.tar.*
  fi
else
  echo "Note: Cursor and Warp require a desktop session — skipped."
fi

sed -i '/bash ~\/.first_run_gui.sh/d' ~/.bashrc
rm -f ~/.first_run_gui.sh
touch ~/.setup_done

if $HAS_GUI; then
  zenity --info --title="Setup Complete" \
    --text="Done! Re-open your terminal to activate NVM."
else
  echo "=== Setup complete! Re-open your shell to activate NVM. ==="
fi
SCRIPT

        chmod +x /etc/skel/.first_run_gui.sh

        grep -qxF 'bash ~/.first_run_gui.sh' /etc/skel/.bashrc 2>/dev/null || \
          echo 'bash ~/.first_run_gui.sh' >> /etc/skel/.bashrc

        grep -qxF 'alias abacusai=' /etc/skel/.bashrc 2>/dev/null || \
          echo 'alias abacusai="$HOME/.abacusai_tool/node_modules/.bin/abacusai"' \
            >> /etc/skel/.bashrc
      '';
    };
  };
}
