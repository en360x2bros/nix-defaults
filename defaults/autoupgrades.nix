{
  config,
  pkgs,
  lib,
  ...
}:

{
  config = {
    system.autoUpgrade = {
      enable = true;
      channel = "https://nixos.org/channels/nixos-unstable";
      dates = "daily";
    };
  };
}
