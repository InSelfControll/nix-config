{ pkgs, ... }: {
  environment.systemPackages = with pkgs; [
    git curl wget vim pciutils jq openssh htop tree unzip
  ];
}
