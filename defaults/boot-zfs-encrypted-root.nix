{
  lib,
  pkgs,
  config,
  ...
}:
{
  config = {
    boot.kernelPackages = pkgs.linuxPackagesFor pkgs.linux_6_12;
    boot.supportedFilesystems.zfs = lib.mkDefault true;
    boot.zfs.package = lib.mkDefault pkgs.zfs_2_3;
    boot.zfs.requestEncryptionCredentials = lib.mkDefault true;
    boot.initrd.network.postCommands = lib.mkDefault ''
      # Import all pools
      zpool import -a
      # Add the load-key command to the .profile
      echo "zfs load-key -a; killall zfs" >> /root/.profile
    '';
  };
}
