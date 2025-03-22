{
  config,
  pkgs,
  lib,
  ...
}:

{
  config = {
    virtualisation.incus.enable = lib.mkDefault true;
    virtualisation.incus.package = pkgs.incus;
    virtualisation.incus.ui.enable = lib.mkDefault false;
  };
}
