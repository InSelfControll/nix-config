{ pkgs, ... }: {
  imports = [ /etc/nixos/hardware-configuration.nix ];

  networking.hostName = "nixos";
  networking.networkmanager.enable = true;

  time.timeZone = "Asia/Jerusalem";

  i18n.defaultLocale = "en_US.UTF-8";
  i18n.extraLocaleSettings = {
    LC_ADDRESS        = "he_IL.UTF-8";
    LC_IDENTIFICATION = "he_IL.UTF-8";
    LC_MEASUREMENT    = "he_IL.UTF-8";
    LC_MONETARY       = "he_IL.UTF-8";
    LC_NAME           = "he_IL.UTF-8";
    LC_NUMERIC        = "he_IL.UTF-8";
    LC_PAPER          = "he_IL.UTF-8";
    LC_TELEPHONE      = "he_IL.UTF-8";
    LC_TIME           = "he_IL.UTF-8";
  };

  services.xserver.enable = true;
  services.xserver.xkb.layout = "us";

  services.displayManager.sddm.enable = true;
  services.desktopManager.plasma6.enable = true;

  environment.plasma6.excludePackages = with pkgs.kdePackages; [
    kate elisa okular gwenview spectacle plasma-browser-integration
  ];

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
