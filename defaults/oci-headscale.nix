{
  config,
  pkgs,
  lib,
  ...
}:

{
  config = {
    virtualisation.oci-containers.containers."headscale-server" = {
      image = lib.mkDefault "docker.io/headscale/headscale:v0.25.1";
      autoStart = true;
      volumes = [
        "/etc/headscale:/etc/headscale:ro"
        "headscale-data:/var/lib/headscale"
      ];
      cmd = [ "serve" ];
    };
  };
}
