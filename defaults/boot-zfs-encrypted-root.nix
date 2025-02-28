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

    boot.initrd.postDeviceCommands = lib.mkDefault ''
      # Import all pools
      zpool import -a
      # Add the load-key command to the .profile
      echo "#!/bin/sh" > /bin/askpass-zfs
      echo "zfs load-key -a; killall zfs" >> /bin/askpass-zfs
      chmod +x /bin/askpass-zfs
    '';
    boot.initrd.network.ssh.shell = "/bin/askpass-zfs";
  };
}
