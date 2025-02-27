{
  config,
  pkgs,
  lib,
  ...
}:

{
  config = {
    boot.initrd.network.enable = true;
    boot.initrd.network.ssh.enable = true;
    boot.initrd.network.ssh.port = 2222;
    boot.initrd.network.ssh.hostKeys = [
      "/etc/ssh/ssh_host_ed25519_key"
    ];
    boot.initrd.network.ssh.authorizedKeys = config.mgmt.sshKeys;
  };
}
