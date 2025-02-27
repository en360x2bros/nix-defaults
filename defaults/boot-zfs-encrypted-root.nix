  boot = {
    kernelPackages = pkgs.linuxPackagesFor pkgs.linux_6_12;
    supportedFilesystems.zfs = true;
    zfs.package = pkgs.zfs_2_3;
    zfs.requestEncryptionCredentials = true;
    initrd.network = {
        postCommands = ''
        # Import all pools
        zpool import -a
        # Add the load-key command to the .profile
        echo "zfs load-key -a; killall zfs" >> /root/.profile
        '';
      };
  };