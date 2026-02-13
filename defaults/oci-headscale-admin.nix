{
  config,
  pkgs,
  lib,
  ...
}:

{
  config = {
    virtualisation.oci-containers.containers."headscale-admin" = {
      image = lib.mkDefault "docker.io/goodieshq/headscale-admin:0.25.6";
      autoStart = true;
    };
  };
}