{ lib, pkgs, config, ... }:
{
  config = {
    services.zfs.zed.settings = {
      ZED_EMAIL_ADDR = [ "root" ];
      ZED_EMAIL_OPTS = "@ADDRESS@";

      ZED_NOTIFY_INTERVAL_SECS = 3600;
      ZED_NOTIFY_VERBOSE = true;

      ZED_SCRUB_AFTER_RESILVER = true;
    };
  };
}