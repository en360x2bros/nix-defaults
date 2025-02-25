{
  description = "Shared NixOS Defaults of encircle360 GmbH and 2Bros Digital Group GmbH (short: en360x2bros)";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs = { self, nixpkgs }: {
    nixosModules = {
      autoupgrades = import ./defaults/autoupgrades.nix;
      dns = import ./defaults/dns.nix;
      incus = import ./defaults/incus.nix;
      locale = import ./defaults/locale.nix;
      maintenance = import ./defaults/maintenance.nix;
      mgmt = import ./defaults/mgmt.nix;
      ntp = import ./defaults/ntp.nix;
      packages = import ./defaults/packages.nix;
      rclone = import ./defaults/rclone.nix;
      timezone = import ./defaults/timezone.nix;
      boot-systemd = import ./defaults/boot-systemd.nix;
      boot-grub = import ./defaults/boot-grub.nix;
    };
  };
}