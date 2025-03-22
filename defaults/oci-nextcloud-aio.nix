{
  config,
  pkgs,
  lib,
  ...
}:

{
  config = {
    virtualisation.oci-containers.containers = {
      "nextcloud-aio-mastercontainer" = {
        serviceName = "docker-nextcloud-aio";
        image = lib.mkDefault "nextcloud/all-in-one:20250306_093458";
        autoStart = true;
        volumes = [
          "nextcloud_aio_mastercontainer:/mnt/docker-aio-config"
          "/var/run/docker.sock:/var/run/docker.sock"
        ];
        environment = {
          "APACHE_PORT" = "11000";
          "APACHE_IP_BINDING" = "0.0.0.0";
          "APACHE_ADDITIONAL_NETWORK" = "";
          "SKIP_DOMAIN_VALIDATION" = "false";
        };
        extraOptions = [
          "--init"
          "--sig-proxy=false"
          # "--network=host"
        ];
      };
    };
  };
}