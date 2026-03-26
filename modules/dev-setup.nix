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

mkdir -p ~/.nixos-features ~/Applications ~/.local/share/applications

# ── Detect GUI session ────────────────────────────────────────────────────
HAS_GUI=false
[ -n "$DISPLAY" ] || [ -n "$WAYLAND_DISPLAY" ] && HAS_GUI=true

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

# ── Stack selection ───────────────────────────────────────────────────────
CHOICES=""

if $HAS_GUI; then
  CHOICES=$(zenity --list --checklist \
    --title="NixOS Developer Setup" \
    --width=500 --height=500 \
    --column="Install" --column="Tool" \
    TRUE  "Web (Node 22.21 via NVM)" \
    TRUE  "AbacusAI CLI" \
    TRUE  "AbacusAI Desktop" \
    TRUE  "Cursor" \
    TRUE  "Warp Terminal" \
    TRUE  "Claude Desktop" \
    TRUE  "Claude Code CLI" \
    TRUE  "LM Studio" \
    TRUE  "Google Antigravity" \
    FALSE "Mobile (Expo + JDK21)" \
    --separator="|") || exit 0
else
  echo "=== NixOS Developer Setup (headless) ==="
  echo "No display — GUI apps will be skipped."
  echo ""
  read -rp "Web stack (Node 22.21)? [Y/n] " ans; [[ "$ans" =~ ^[Nn] ]] || CHOICES+="|Web (Node 22.21 via NVM)"
  read -rp "AbacusAI CLI? [Y/n] " ans;           [[ "$ans" =~ ^[Nn] ]] || CHOICES+="|AbacusAI CLI"
  read -rp "Claude Code CLI? [Y/n] " ans;         [[ "$ans" =~ ^[Nn] ]] || CHOICES+="|Claude Code CLI"
  read -rp "Mobile (Expo + JDK21)? [y/N] " ans;  [[ "$ans" =~ ^[Yy] ]] && CHOICES+="|Mobile (Expo + JDK21)"
fi

# ── Feature markers ───────────────────────────────────────────────────────
[[ "$CHOICES" == *"Web"*          ]] && touch ~/.nixos-features/web
[[ "$CHOICES" == *"AbacusAI CLI"* ]] && touch ~/.nixos-features/abacusai-cli
[[ "$CHOICES" == *"AbacusAI Desktop"* ]] && touch ~/.nixos-features/abacusai-desktop
[[ "$CHOICES" == *"Cursor"*       ]] && touch ~/.nixos-features/cursor
[[ "$CHOICES" == *"Warp"*         ]] && touch ~/.nixos-features/warp
[[ "$CHOICES" == *"Claude Desktop"* ]] && touch ~/.nixos-features/claude-desktop
[[ "$CHOICES" == *"Claude Code"*  ]] && touch ~/.nixos-features/claude-code
[[ "$CHOICES" == *"LM Studio"*    ]] && touch ~/.nixos-features/lmstudio
[[ "$CHOICES" == *"Antigravity"*  ]] && touch ~/.nixos-features/antigravity
[[ "$CHOICES" == *"Mobile"*       ]] && touch ~/.nixos-features/mobile

# ── Web: NVM + Node 22.21 ─────────────────────────────────────────────────
if [[ "$CHOICES" == *"Web"* ]]; then
  echo "==> Installing NVM + Node 22.21..."
  export NVM_DIR="$HOME/.nvm"
  curl -fsSo- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash
  [ -s "$NVM_DIR/nvm.sh" ] && source "$NVM_DIR/nvm.sh"
  nvm install 22.21 && nvm alias default 22.21
fi

# ── AbacusAI CLI ──────────────────────────────────────────────────────────
if [[ "$CHOICES" == *"AbacusAI CLI"* ]]; then
  echo "==> Installing AbacusAI CLI..."
  export NVM_DIR="$HOME/.nvm"
  [ -s "$NVM_DIR/nvm.sh" ] && source "$NVM_DIR/nvm.sh"
  npm install -g @abacus-ai/cli
fi

# ── Claude Code CLI ───────────────────────────────────────────────────────
if [[ "$CHOICES" == *"Claude Code"* ]]; then
  echo "==> Installing Claude Code CLI..."
  export NVM_DIR="$HOME/.nvm"
  [ -s "$NVM_DIR/nvm.sh" ] && source "$NVM_DIR/nvm.sh"
  npm install -g @anthropic-ai/claude-code
fi

# ── Mobile: Expo + JDK21 ─────────────────────────────────────────────────
if [[ "$CHOICES" == *"Mobile"* ]]; then
  echo "==> Installing Expo CLI..."
  export NVM_DIR="$HOME/.nvm"
  [ -s "$NVM_DIR/nvm.sh" ] && source "$NVM_DIR/nvm.sh"
  npm install -g expo-cli
fi

# ── GUI-only apps ─────────────────────────────────────────────────────────
if $HAS_GUI; then

  # Cursor AppImage
  if [[ "$CHOICES" == *"Cursor"* ]]; then
    echo "==> Downloading Cursor..."
    CURSOR_URL=$(curl -fsSL \
      "https://www.cursor.com/api/download?platform=linux-x64&releaseTrack=stable" \
      | jq -r '.downloadUrl')
    curl -fSL "$CURSOR_URL" -o ~/Applications/cursor.AppImage
    chmod +x ~/Applications/cursor.AppImage
    cat > ~/.local/share/applications/cursor.desktop << 'DESK'
[Desktop Entry]
Name=Cursor
Comment=AI Code Editor
Exec=/bin/sh -c 'cd ~ && ~/Applications/cursor.AppImage --no-sandbox'
Icon=cursor
Terminal=false
Type=Application
Categories=Development;IDE;
StartupWMClass=Cursor
DESK
  fi

  # Warp Terminal
  if [[ "$CHOICES" == *"Warp"* ]]; then
    echo "==> Downloading Warp..."
    WARP_URL="https://releases.warp.dev/stable/v0.2025.03.18.08.02.stable_00/warp-terminal_0.2025.03.18.08.02.stable.00_amd64.deb"
    curl -fSL "$WARP_URL" -o /tmp/warp.deb
    cd /tmp && ar x warp.deb && tar -xf data.tar.* ./usr/bin/warp-terminal
    mv /tmp/usr/bin/warp-terminal ~/Applications/warp
    chmod +x ~/Applications/warp
    rm -f /tmp/warp.deb /tmp/data.tar.* /tmp/control.tar.*
    cat > ~/.local/share/applications/warp.desktop << 'DESK'
[Desktop Entry]
Name=Warp
Comment=AI Terminal
Exec=~/Applications/warp
Icon=utilities-terminal
Terminal=false
Type=Application
Categories=System;TerminalEmulator;
StartupWMClass=WarpTerminal
DESK
  fi

  # AbacusAI Desktop
  if [[ "$CHOICES" == *"AbacusAI Desktop"* ]]; then
    echo "==> Downloading AbacusAI Desktop..."
    ABACUS_URL=$(curl -fsSL "https://api.github.com/repos/abacusai/deepagent-releases/releases/latest" \
      | jq -r '.assets[] | select(.name | test("linux-x64.*\\.tar\\.gz")) | .browser_download_url' | head -1)
    curl -fSL "$ABACUS_URL" -o /tmp/abacusai.tar.gz
    mkdir -p ~/Applications/abacusai
    tar -xzf /tmp/abacusai.tar.gz -C ~/Applications/abacusai --strip-components=1
    rm -f /tmp/abacusai.tar.gz
    # Find the main binary
    ABACUS_BIN=$(find ~/Applications/abacusai -maxdepth 2 -name "abacusai" -o -name "AbacusAI" 2>/dev/null | head -1)
    cat > ~/.local/share/applications/abacusai.desktop << DESK
[Desktop Entry]
Name=AbacusAI Desktop
Comment=AI Coding Assistant
Exec=$ABACUS_BIN --no-sandbox
Icon=abacusai
Terminal=false
Type=Application
Categories=Development;IDE;
DESK
  fi

  # Claude Desktop (AppImage from aaddrick/claude-desktop-debian)
  if [[ "$CHOICES" == *"Claude Desktop"* ]]; then
    echo "==> Downloading Claude Desktop..."
    CLAUDE_URL=$(curl -fsSL "https://api.github.com/repos/aaddrick/claude-desktop-debian/releases/latest" \
      | jq -r '.assets[] | select(.name | test("amd64\\.AppImage")) | .browser_download_url' | head -1)
    curl -fSL "$CLAUDE_URL" -o ~/Applications/claude-desktop.AppImage
    chmod +x ~/Applications/claude-desktop.AppImage
    cat > ~/.local/share/applications/claude-desktop.desktop << 'DESK'
[Desktop Entry]
Name=Claude Desktop
Comment=Anthropic Claude AI Assistant
Exec=/bin/sh -c 'cd ~ && ~/Applications/claude-desktop.AppImage --no-sandbox'
Icon=claude
Terminal=false
Type=Application
Categories=Utility;AI;
StartupWMClass=Claude
DESK
  fi

  # LM Studio
  if [[ "$CHOICES" == *"LM Studio"* ]]; then
    echo "==> Downloading LM Studio..."
    LMS_VERSION=$(curl -fsSL "https://lmstudio.ai/api/releases/latest" 2>/dev/null \
      | jq -r '.version' 2>/dev/null || echo "0.3.6")
    LMS_URL="https://installers.lmstudio.ai/linux/x64/${LMS_VERSION}/LM-Studio-${LMS_VERSION}-x64.AppImage"
    curl -fSL "$LMS_URL" -o ~/Applications/lmstudio.AppImage || \
      curl -fSL "https://lmstudio.ai/download?os=linux" -o ~/Applications/lmstudio.AppImage
    chmod +x ~/Applications/lmstudio.AppImage
    cat > ~/.local/share/applications/lmstudio.desktop << 'DESK'
[Desktop Entry]
Name=LM Studio
Comment=Run Local LLMs
Exec=/bin/sh -c 'cd ~ && ~/Applications/lmstudio.AppImage --no-sandbox'
Icon=lmstudio
Terminal=false
Type=Application
Categories=Development;AI;
DESK
  fi

  # Google Antigravity
  if [[ "$CHOICES" == *"Antigravity"* ]]; then
    echo "==> Downloading Google Antigravity..."
    curl -fsSL "https://antigravity.google/download/linux" -o /tmp/antigravity-install.sh 2>/dev/null || \
    curl -fsSL "https://dl.google.com/antigravity/linux/direct/antigravity_linux_x64.tar.gz" -o /tmp/antigravity.tar.gz 2>/dev/null
    if [ -f /tmp/antigravity.tar.gz ]; then
      mkdir -p ~/Applications/antigravity
      tar -xzf /tmp/antigravity.tar.gz -C ~/Applications/antigravity --strip-components=1
      rm -f /tmp/antigravity.tar.gz
      ANTI_BIN=$(find ~/Applications/antigravity -maxdepth 2 -name "antigravity" 2>/dev/null | head -1)
    elif [ -f /tmp/antigravity-install.sh ]; then
      bash /tmp/antigravity-install.sh --install-dir ~/Applications/antigravity
      ANTI_BIN="$HOME/Applications/antigravity/antigravity"
      rm -f /tmp/antigravity-install.sh
    fi
    cat > ~/.local/share/applications/antigravity.desktop << DESK
[Desktop Entry]
Name=Google Antigravity
Comment=Agent-first AI Development Platform
Exec=$ANTI_BIN
Icon=antigravity
Terminal=false
Type=Application
Categories=Development;IDE;
DESK
  fi

fi  # end HAS_GUI

# ── Refresh KDE app menu ──────────────────────────────────────────────────
if $HAS_GUI; then
  update-desktop-database ~/.local/share/applications 2>/dev/null || true
  kbuildsycoca6 2>/dev/null || true
fi

# ── Cleanup ───────────────────────────────────────────────────────────────
sed -i '/bash ~\/.first_run_gui.sh/d' ~/.bashrc
rm -f ~/.first_run_gui.sh
touch ~/.setup_done

if $HAS_GUI; then
  zenity --info --title="Setup Complete" \
    --text="All tools installed!\nRe-open terminal to activate NVM and aliases."
else
  echo "=== Setup complete! Re-open shell to activate. ==="
fi
SCRIPT

      chmod +x /etc/skel/.first_run_gui.sh

      grep -qxF 'bash ~/.first_run_gui.sh' /etc/skel/.bashrc 2>/dev/null || \
        echo 'bash ~/.first_run_gui.sh' >> /etc/skel/.bashrc

      grep -qxF 'alias abacusai=' /etc/skel/.bashrc 2>/dev/null || \
        echo 'alias abacusai="$HOME/.nvm/versions/node/$(ls $HOME/.nvm/versions/node 2>/dev/null | tail -1)/bin/abacusai"' \
          >> /etc/skel/.bashrc

      grep -qxF 'alias claude=' /etc/skel/.bashrc 2>/dev/null || \
        echo 'alias claude="$HOME/.nvm/versions/node/$(ls $HOME/.nvm/versions/node 2>/dev/null | tail -1)/bin/claude"' \
          >> /etc/skel/.bashrc
    '';
  };
}

