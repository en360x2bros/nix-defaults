{
  config,
  pkgs,
  lib,
  ...
}:

{
  config = {
    virtualisation.oci-containers.containers."headscale-admin" = {
      image = lib.mkDefault "docker.io/goodieshq/headscale-admin:0.25.2";
      autoStart = true;
    };
  };
}
