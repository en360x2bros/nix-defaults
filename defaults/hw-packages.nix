{
  config,
  pkgs,
  lib,
  ...
}:
{
  environment.systemPackages = with pkgs; [
    lm_sensors
    usbutils
    ethtool
    pciutils
    smartmontools
  ];
}
