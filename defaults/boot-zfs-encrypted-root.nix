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
    boot.zfs.package = lib.mkDefault pkgs.zfs_2_4;
    boot.zfs.requestEncryptionCredentials = lib.mkDefault true;

    boot.initrd.systemd.services.initrd-zfs-askpass = lib.mkDefault {
      description = "Prepare ZFS askpass helper for initrd SSH unlock";
      wantedBy = [ "initrd.target" ];
      unitConfig.DefaultDependencies = "no";

      serviceConfig = {
        Type = "oneshot";
        StandardOutput = "journal+console";
        StandardError = "journal+console";
      };

      script = ''
        cat > /bin/askpass-zfs <<'EOF'
        #!/bin/sh
        echo "Press CTRL+C to enter shell..."
        trap '/bin/sh; exit' INT
        sleep 3
        trap - INT

        # Show and process systemd password prompts (incl. ZFS key requests)
        exec /bin/systemd-tty-ask-password-agent --watch
        EOF
        chmod +x /bin/askpass-zfs
      '';
    };

    boot.initrd.network.ssh.shell = "/bin/askpass-zfs";
  };
}