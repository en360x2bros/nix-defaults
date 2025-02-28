{ lib, pkgs, config, ... }:
{
  config = {
    services.zfs.autoScrub.enable = lib.mkDefault true;
    services.zfs.trim.enable = lib.mkDefault true;

    environment.systemPackages = with pkgs; [
      zfs
    ];
  };
}
