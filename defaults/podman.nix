{
  config,
  pkgs,
  lib,
  ...
}:

{
  config = {
    environment.systemPackages = with pkgs; [
      ctop
      lazydocker
    ];

    virtualisation = {
      oci-containers.backend = "podman";

      podman = {
        enable = true;
        dockerCompat = true;
        defaultNetwork.settings.dns_enabled = true;
        dockerSocket.enable = true;
        defaultNetwork.settings = {
          ipv6_enabled = true;

          subnets = [
            {
              subnet = "10.88.0.0/16";
              gateway = "10.88.0.1";
            }
            {
              subnet = "fde9:d35e:57dc::/48";
              gateway = "fde9:d35e:57dc::1";
            }
          ];
        };
        autoPrune = {
          enable = true;
          dates = "weekly";
          flags = [
            "--filter=until=24h"
            "--filter=label!=important"
          ];
        };
      };
    };

    environment.variables.DOCKER_HOST = "unix:///run/podman/podman.sock";
  };
}