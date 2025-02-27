{ lib, pkgs, ... }:
{
  boot = {
    kernelPackages = pkgs.linuxPackagesFor pkgs.linux_6_12;
    supportedFilesystems.zfs = lib.mkDefault true;
    zfs.package = lib.mkDefault pkgs.zfs_2_3;
    zfs.requestEncryptionCredentials = lib.mkDefault true;
    initrd.network = {
      postCommands = lib.mkDefault ''
        # Import all pools
        zpool import -a
        # Add the load-key command to the .profile
        echo "zfs load-key -a; killall zfs" >> /root/.profile
      '';
    };
  };
}
