{
  config,
  pkgs,
  lib,
  ...
}:

{
  config = {
    services.logrotate = {
      enable = true;
      settings = {
        "/var/log/**/*.log" = {
          rotate = 7;
          daily = true;
          missingok = true;
          compress = true;
          delaycompress = true;
          notifempty = true;
          copytruncate = false;
        };
      };
    };
  };
}
