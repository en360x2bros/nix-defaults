{
  config,
  pkgs,
  lib,
  ...
}:

{
  config = {
    virtualisation.incus.enable = lib.mkDefault true;
    virtualisation.incus.package = lib.mkDefault pkgs.incus;
    virtualisation.incus.ui.enable = lib.mkDefault false;
  };
}
