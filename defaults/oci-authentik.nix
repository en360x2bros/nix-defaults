{
  config,
  pkgs,
  lib,
  ...
}:

{
  config = {
    # NOT IN USE
    virtualisation.oci-containers.containers = {
      authentik-server = {
        image = "ghcr.io/goauthentik/server:2025.6.4";
        autoStart = true;
        cmd = [ "server" ];
        volumes = [
          "authentik-media:/media"
          "authentik-templates:/templates"
        ];
        networks = lib.mkDefault [ "authentik" ];
        dependsOn = [ "authentik-postgresql" "authentik-redis" ];
      };

      authentik-worker = {
        image = "ghcr.io/goauthentik/server:2025.6.4";
        autoStart = true;
        cmd = [ "worker" ];
        volumes = [
          "/var/run/docker.sock:/var/run/docker.sock"
          "authentik-media:/media"
          "authentik-templates:/templates"
          "authentik-certs:/certs"
        ];
        networks = lib.mkDefault [ "authentik" ];
        dependsOn = [ "authentik-postgresql" "authentik-redis" ];
      };
    };
  };
}