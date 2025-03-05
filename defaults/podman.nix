{
  config,
  pkgs,
  lib,
  ...
}:

{
  config = {
    environment.systemPackages = with pkgs; [
      podman-compose
    ];

    virtualisation = {
      oci-containers.backend = "podman";

      podman = {
        enable = true;
        dockerCompat = true;
        autoPrune = {
          enable = true;
          dates = "weekly";
          flags = [
            "--filter=until=24h"
            "--filter=label!=important"
          ];
        };

        defaultNetwork.settings.dns_enabled = true;
      };
    };
  };
}
