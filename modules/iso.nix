systemd.services.bootstrap-system = {
  description = "Bootstrap NixOS from Git flake";
  wantedBy = [ "multi-user.target" ];
  after = [ "network-online.target" ];

  serviceConfig = {
    Type = "oneshot";
    RemainAfterExit = true;
  };

  script = ''
    echo "Bootstrapping system from GitHub..."

    nixos-rebuild switch \
      --flake github:InSelfControll/nix-config#home-desktop

    echo "Bootstrap complete"
  '';
};
