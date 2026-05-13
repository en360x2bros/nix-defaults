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


    boot.initrd.systemd.services.initrd-zfs-askpass = lib.mkDefault {
      description = "Prepare ZFS askpass helper for initrd SSH unlock";
      wantedBy = [ "initrd.target" ];
      before = [ "sshd.service" ];
      after = [ "systemd-udev-settle.service" ];
      wants = [ "systemd-udev-settle.service" ];
      unitConfig.DefaultDependencies = "no";

      serviceConfig = {
        Type = "oneshot";
        StandardOutput = "journal+console";
        StandardError = "journal+console";
      };

      script = ''
        zpool import -a || true

        cat > /bin/askpass-zfs <<'EOF'
        #!/bin/sh
        echo "Press CTRL+C to enter shell..."
        trap '/bin/bash; exit' INT
        sleep 3
        trap - INT
        zfs load-key -a

        systemctl restart zfs-import-zroot.service || true
        EOF
        chmod +x /bin/askpass-zfs
      '';
    };

    boot.initrd.network.ssh.shell = "/bin/askpass-zfs";
  };
}