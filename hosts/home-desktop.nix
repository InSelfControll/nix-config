{ ... }: {
  networking.hostName = "nixos";
  networking.networkmanager.enable = true;

  time.timeZone = "Asia/Jerusalem";
  i18n.defaultLocale = "en_IL";

  services.xserver.enable = true;
  services.xserver.xkb.layout = "us";

  services.printing.enable = true;

  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  users.users.ofir = {
    isNormalUser = true;
    description = "ofir";
    extraGroups = [ "networkmanager" "wheel" ];
  };

  programs.firefox.enable = true;
}
