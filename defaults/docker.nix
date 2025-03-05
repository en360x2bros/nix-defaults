{
  config,
  pkgs,
  lib,
  ...
}:

{
  config = {
    virtualisation.oci-containers.backend = "docker";
  };
}