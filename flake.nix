{
  description = "Shared NixOS Defaults of en360x2bros";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs = { self, nixpkgs }: {
    nixosModules = {
      mgmt = import ./defaults/mgmt.nix;
      dns = import ./defaults/dns.nix;
      packages = import ./defaults/packages.nix;
    };
  };
}