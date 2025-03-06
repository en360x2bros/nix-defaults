{
  description = "Shared NixOS Defaults of encircle360 GmbH and 2Bros Digital Group GmbH (short: en360x2bros)";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs =
    { self, nixpkgs }:
    {
      nixosModules = {
        autoupgrades = import ./defaults/autoupgrades.nix;
        boot-grub = import ./defaults/boot-grub.nix;
        boot-initrd-sshd = import ./defaults/boot-initrd-sshd.nix;
        boot-luks-encrypted-root = import ./defaults/boot-luks-encrypted-root.nix;
        boot-systemd = import ./defaults/boot-systemd.nix;
        boot-zfs-encrypted-root = import ./defaults/boot-zfs-encrypted-root.nix;
        dns = import ./defaults/dns.nix;
        docker = import ./defaults/docker.nix;
        incus = import ./defaults/incus.nix;
        locale = import ./defaults/locale.nix;
        logrotate = import ./defaults/logrotate.nix;
        maintenance = import ./defaults/maintenance.nix;
        mgmt = import ./defaults/mgmt.nix;
        motd = import ./defaults/motd.nix;
        ntp = import ./defaults/ntp.nix;
        oci-caddy-docker-proxy = import ./defaults/oci-caddy-docker-proxy.nix;
        oci-hcloud-snapshot-as-backup = import ./defaults/oci-hcloud-snapshot-as-backup.nix;
        oci-headscale = import ./defaults/oci-headscale.nix;
        packages = import ./defaults/packages.nix;
        podman = import ./defaults/podman.nix;
        rclone = import ./defaults/rclone.nix;
        swap = import ./defaults/swap.nix;
        timezone = import ./defaults/timezone.nix;
        zfs-maintenance = import ./defaults/zfs-maintenance.nix;
        hw-packages = import ./defaults/hw-packages.nix;
      };
    };
}
