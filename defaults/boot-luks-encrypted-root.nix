{
  lib,
  pkgs,
  config,
  ...
}:
{
  config = {
    boot.initrd.preDeviceCommands = lib.mkDefault ''
      echo "#!/bin/sh" > /bin/askpass-luks
      echo "echo \"Press CTRL+C to enter shell...\"" >> /bin/askpass-luks
      echo "trap '/bin/ash; exit' INT" >> /bin/askpass-luks
      echo "sleep 3" >> /bin/askpass-luks
      echo "trap - INT" >> /bin/askpass-luks
      echo "/bin/cryptsetup-askpass" >> /bin/askpass-luks
      chmod +x /bin/askpass-luks
    '';
    boot.initrd.network.ssh.shell = "/bin/askpass-luks";
  };
}