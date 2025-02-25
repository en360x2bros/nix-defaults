{
  config,
  pkgs,
  lib,
  ...
}:

{
  config = {
    services.ntp = {
      enable = true;
      servers = [ "pool.ntp.org" ];
    };
  };
}
