{
  config,
  pkgs,
  lib,
  ...
}:

{
  config = {
    services.ntp.enable = lib.mkForce false;
    services.chrony = {
      enable = true;
      servers = [
        "0.de.pool.ntp.org"
        "1.de.pool.ntp.org"
        "2.de.pool.ntp.org"
        "3.de.pool.ntp.org"
      ];
      extraConfig = ''
        makestep 1.0 3
        rtcsync
      '';
    };
  };
}
