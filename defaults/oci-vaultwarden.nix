{
  config,
  pkgs,
  lib,
  ...
}:

{
  config = {
    virtualisation.oci-containers.containers."vaultwarden" = {
      image = lib.mkDefault "docker.io/vaultwarden/server:1.33.2";
      autoStart = true;
      volumes = [
        "vaultwarden-data:/data"
      ];
    };
  };
}