{ pkgs, ... }: {
  environment.systemPackages = with pkgs; [
    # Dev tools
    bun jdk25 jdk21 appimage-run zenity

    # GUI apps available in nixpkgs
    steam
    virt-manager
    prismlauncher

    # Android SDK tools
    android-tools
  ];

  # Required for virt-manager
  virtualisation.libvirtd.enable = true;
  programs.virt-manager.enable = true;

  # Required for Steam
  hardware.graphics.enable = true;
  hardware.graphics.enable32Bit = true;

  programs.nix-ld = {
    enable = true;
    libraries = with pkgs; [
      stdenv.cc.cc zlib openssl icu libunwind
      xorg.libX11 xorg.libXcursor xorg.libXrandr xorg.libXcomposite
      alsa-lib libglvnd
    ];
  };
}

