{
  config,
  lib,
  pkgs,
  ...
}:

let
  inherit (lib) mkOption types;
in
{
  options.swap.size = mkOption {
    type = types.int;
    default = 1024; # Default: 1 GiB
    description = "Size of the swap file in MiB.";
  };

  config = {
    swapDevices = [
      {
        device = "/swapfile";
        size = config.swap.size;
      }
    ];
  };
}