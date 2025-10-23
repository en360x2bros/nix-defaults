{
  config,
  pkgs,
  lib,
  ...
}:

{
  config = {
    virtualisation.oci-containers.containers."headscale-server" = {
      image = lib.mkDefault "docker.io/headscale/headscale:v0.26.1";
      autoStart = true;
      cmd = [ "serve" ];
    };
  };
}
