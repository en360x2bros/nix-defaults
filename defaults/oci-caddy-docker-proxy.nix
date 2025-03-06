{
  config,
  pkgs,
  lib,
  ...
}:

{
  config = {
    system.activationScripts.ociNetworkCaddy = let
      docker = config.virtualisation.oci-containers.backend;
      dockerBin = "${pkgs.${docker}}/bin/${docker}";
    in ''
      ${dockerBin} network inspect caddy >/dev/null 2>&1 || ${dockerBin} network create caddy
    '';

    virtualisation.oci-containers.containers."caddy-docker-proxy" = {
      image = lib.mkDefault "docker.io/lucaslorentz/caddy-docker-proxy:latest";
      autoStart = true;
      ports = [ "80:80" "443:443" ];
      volumes = [
        "/var/run/docker.sock:/var/run/docker.sock"
        "caddy-docker-proxy-data:/data"
      ];
      environment = lib.mkDefault {
        "CADDY_INGRESS_NETWORKS" = "caddy";
      };
      networks = lib.mkDefault ["caddy"];
    };
  };
}
