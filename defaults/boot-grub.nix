# use with EFI
{ pkgs, ... }:
{
  config = {
    boot = {
      loader = {
        grub = {
          enable = true;
          device = "nodev";
          efiSupport = true;
          zfsSupport = true;
          efiInstallAsRemovable = true;
        };
      };
    };

    environment.systemPackages = with pkgs; [
      efibootmgr
    ];

    systemd.services.log-boot-source = {
      description = "Dump efibootmgr output";
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        Type = "oneshot";
        ExecStart = pkgs.writeShellScript "dump-efibootmgr" ''
          LOGFILE="/var/log/boot-source.log"
          {
            echo "===== $(date '+%Y-%m-%d %H:%M:%S') ====="
            ${pkgs.efibootmgr}/bin/efibootmgr -v
            echo
          } >> "$LOGFILE"
        '';
      };
    };
  };
}