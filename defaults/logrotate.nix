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
          rotate = 7; # Keep logs for 7 rotations (equivalent to 7 days with daily rotation)
          daily = true; # Rotate logs daily
          missingok = true; # Do not report an error if the log file is missing
          compress = true; # Compress old log files to save disk space
          delaycompress = true; # Do not compress the most recently rotated log file immediately
          notifempty = true; # Do not rotate empty log files
          copytruncate = false; # Do not truncate the log file in place; create a new one instead
        };
      };
    };
  };
}
