{ pkgs, ... }: {
  environment.systemPackages = with pkgs; [
    bun jdk21 appimage-run zenity
  ];

  programs.nix-ld = {
    enable = true;
    libraries = with pkgs; [
      stdenv.cc.cc zlib openssl icu libunwind
      xorg.libX11 xorg.libXcursor xorg.libXrandr xorg.libXcomposite
      alsa-lib libglvnd
    ];
  };
}
