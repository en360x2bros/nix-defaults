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
      # Global defaults for all logrotate rules (from NixOS modules like nginx, btmp, wtmp).
      # No catch-all wildcard: NixOS modules that write to /var/log/ bring their own
      # logrotate rules with correct postrotate hooks (e.g. nginx sends USR1).
      # A global "/var/log/**/*.log" would conflict with those module-specific rules.
      settings.header = {
        global = true;
        rotate = 7;
        daily = true;
        missingok = true;
        compress = true;
        delaycompress = true;
        notifempty = true;
      };
    };
  };
}
