{ lib, ... }: {
  nixpkgs.config.allowUnfree = true;

  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  services.openssh = {
    enable = true;
    settings.PermitRootLogin = "yes";
  };

  system.activationScripts.setupSkel = {
    deps = [ "etc" ];
    text = ''
      mkdir -p /etc/skel/.nixos-features

      cat > /etc/skel/.first_run_gui.sh << 'SCRIPT'
#!/usr/bin/env bash
if [ -f ~/.setup_done ]; then exit 0; fi

mkdir -p ~/.nixos-features ~/Applications

HAS_GUI=false

# Check current environment first
[ -n "$DISPLAY" ] || [ -n "$WAYLAND_DISPLAY" ] && HAS_GUI=true

# If running via SSH, detect display from active graphical session
if ! $HAS_GUI; then
  if loginctl list-sessions --no-legend 2>/dev/null | grep -qE "x11|wayland"; then
    HAS_GUI=true
    ACTIVE_SESSION=$(loginctl list-sessions --no-legend | grep -E "x11|wayland" | awk '{print $1}' | head -1)
    if [ -n "$ACTIVE_SESSION" ]; then
      SESSION_USER=$(loginctl show-session "$ACTIVE_SESSION" -p Name --value 2>/dev/null)
      export DISPLAY=$(loginctl show-session "$ACTIVE_SESSION" -p Display --value 2>/dev/null || echo ":0")
      export XAUTHORITY=$(eval echo "~$SESSION_USER/.Xauthority")
      PLASMAPID=$(pgrep -u "$SESSION_USER" plasmashell 2>/dev/null | head -1)
      if [ -n "$PLASMAPID" ]; then
        export DBUS_SESSION_BUS_ADDRESS=$(grep -z DBUS_SESSION_BUS_ADDRESS /proc/$PLASMAPID/environ 2>/dev/null | tr '\0' '\n' | grep DBUS_SESSION || echo "")
      fi
    fi
  fi
fi

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
  export NVM_DIR="$HOME/.nvm"
  curl -fsSo- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash
  [ -s "$NVM_DIR/nvm.sh" ] && source "$NVM_DIR/nvm.sh"
  nvm install 22.21 && nvm alias default 22.21
fi

if [[ "$CHOICES" == *"AbacusAI"* ]]; then
  mkdir -p ~/.abacusai_tool
  cd ~/.abacusai_tool && bun install @abacus-ai/cli
fi

if $HAS_GUI; then
  if [[ "$CHOICES" == *"Cursor"* ]]; then
    CURSOR_URL=$(curl -fsSL \
      "https://www.cursor.com/api/download?platform=linux-x64&releaseTrack=stable" \
      | jq -r '.downloadUrl')
    curl -fSL "$CURSOR_URL" -o ~/Applications/cursor.AppImage
    chmod +x ~/Applications/cursor.AppImage
    # Desktop entry for KDE app menu
    mkdir -p ~/.local/share/applications
    cat > ~/.local/share/applications/cursor.desktop << 'DESKTOP'
[Desktop Entry]
Name=Cursor
Comment=AI Code Editor
Exec=/bin/sh -c 'cd ~ && ~/Applications/cursor.AppImage --no-sandbox'
Icon=cursor
Terminal=false
Type=Application
Categories=Development;IDE;
StartupWMClass=Cursor
DESKTOP
  fi

  if [[ "$CHOICES" == *"Warp"* ]]; then
    WARP_URL="https://releases.warp.dev/stable/v0.2025.03.18.08.02.stable_00/warp-terminal_0.2025.03.18.08.02.stable.00_amd64.deb"
    curl -fSL "$WARP_URL" -o /tmp/warp.deb
    cd /tmp && ar x warp.deb && tar -xf data.tar.* ./usr/bin/warp-terminal
    mv /tmp/usr/bin/warp-terminal ~/Applications/warp
    chmod +x ~/Applications/warp
    rm -f /tmp/warp.deb /tmp/data.tar.* /tmp/control.tar.*
    # Desktop entry for KDE app menu
    mkdir -p ~/.local/share/applications
    cat > ~/.local/share/applications/warp.desktop << 'DESKTOP'
[Desktop Entry]
Name=Warp
Comment=AI Terminal
Exec=~/Applications/warp
Icon=utilities-terminal
Terminal=false
Type=Application
Categories=System;TerminalEmulator;
StartupWMClass=WarpTerminal
DESKTOP
  fi
fi

sed -i '/bash ~\/.first_run_gui.sh/d' ~/.bashrc
rm -f ~/.first_run_gui.sh
touch ~/.setup_done

# Refresh KDE icons, app menu and desktop entries
if $HAS_GUI; then
  # Update desktop database so new .desktop entries are found
  update-desktop-database ~/.local/share/applications 2>/dev/null || true
  # Rebuild icon cache
  gtk-update-icon-cache 2>/dev/null || true
  # Tell KDE to reload applications menu
  kbuildsycoca6 2>/dev/null || true
  # Notify KDE of config changes
  dbus-send --session --dest=org.kde.KSycoca     /KSycoca org.kde.KSycoca.databaseChanged 2>/dev/null || true

  zenity --info --title="Setup Complete"     --text="Done! Your apps are ready.\nRe-open terminal to activate NVM."
else
  echo "=== Setup complete! Re-open shell to activate NVM. ==="
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
}

