{ config, pkgs, lib, ... }:

{
  config = {
    nix.settings = {
      auto-optimise-store = true; # Automatically optimise the Nix store
    };

    # Sets /tmp and /var/tmp to 1777 root:root, cleaning up after 7d and 14d
    systemd.tmpfiles.rules = [
      "d /tmp 1777 root root 7d"
      "d /var/tmp 1777 root root 14d"
    ];
  };
}