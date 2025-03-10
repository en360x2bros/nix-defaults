{
  config,
  pkgs,
  lib,
  ...
}:

{
  config = {
    virtualisation.oci-containers.containers."headscale-headplane" = {
      image = lib.mkDefault "ghcr.io/tale/headplane:0.5.3";
      autoStart = true;
    };
  };
}