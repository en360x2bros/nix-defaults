{
  config,
  pkgs,
  lib,
  ...
}:

{
  config = {
    system.activationScripts.ociNetworkAuthentik = let
      docker = config.virtualisation.oci-containers.backend;
      dockerBin = "${pkgs.${docker}}/bin/${docker}";
    in ''
      ${dockerBin} network inspect authentik >/dev/null 2>&1 || ${dockerBin} network create authentik
    '';

    virtualisation.oci-containers.containers = {
      authentik-postgresql = {
        image = "docker.io/library/postgres:16-alpine";
        autoStart = true;
        volumes = [
          "authentik-postgresql:/var/lib/postgresql/data"
        ];
        networks = lib.mkDefault [ "authentik" ];
        extraOptions = [
          "--health-cmd" "pg_isready -d authentik -U authentik"
          "--health-interval" "30s"
          "--health-timeout" "5s"
          "--health-retries" "5"
          "--health-start-period" "20s"
        ];
      };

      authentik-redis = {
        image = "docker.io/library/redis:alpine";
        autoStart = true;
        cmd = [ "--save" "60" "1" "--loglevel" "warning" ];
        volumes = [
          "authentik-redis:/data"
        ];
        networks = lib.mkDefault [ "authentik" ];
        extraOptions = [
          "--health-cmd" "redis-cli ping | grep PONG"
          "--health-interval" "30s"
          "--health-timeout" "3s"
          "--health-retries" "5"
          "--health-start-period" "20s"
        ];
      };

      authentik-server = {
        image = "ghcr.io/goauthentik/server:2025.4.1";
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
        image = "ghcr.io/goauthentik/server:2025.4.1";
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