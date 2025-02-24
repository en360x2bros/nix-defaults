{
  description = "Shared NixOS Defaults of en360x2bros";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs = { self, nixpkgs }: {
    nixosModules = {
      dns = import ./defaults/dns.nix;
      incus = import ./defaults/incus.nix;
      locale = import ./defaults/locale.nix;
      mgmt = import ./defaults/mgmt.nix;
      packages = import ./defaults/packages.nix;
      rclone = import ./defaults/rclone.nix;
      timezone = import ./defaults/timezone.nix;
    };
  };
}