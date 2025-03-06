{
  config,
  pkgs,
  lib,
  ...
}:

{
  config = {
    virtualisation.oci-containers.containers."hcloud-snapshot-as-backup" = {
      image = lib.mkDefault "docker.io/fbrettnich/hcloud-snapshot-as-backup:latest";
      autoStart = true;
      environment = {
        "SNAPSHOT_NAME" = "%name%-%timestamp%";
        "LABEL_SELECTOR" = "AUTOBACKUP";
        "KEEP_LAST" = "3";
        "CRON" = "0 * * * *";
      };
      volumes = [
        "/etc/localtime:/etc/localtime:ro"
      ];
    };
  };
}