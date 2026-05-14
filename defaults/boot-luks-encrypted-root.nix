{ lib, pkgs, ... }:
{
  boot.initrd.systemd.services.askpass-luks-script = {
    description = "Create /bin/askpass-luks for SSH unlock shell";
    wantedBy = [ "initrd.target" ];
    before = [ "cryptsetup.target" ];
    serviceConfig.Type = "oneshot";
    script = ''
      cat > /bin/askpass-luks <<'EOF'
      #!/bin/sh
      echo "Press CTRL+C to enter shell..."
      trap '/bin/sh; exit' INT
      sleep 3
      trap - INT
      exec /bin/systemd-tty-ask-password-agent --watch
      EOF
      chmod +x /bin/askpass-luks
    '';
  };

  boot.initrd.network.ssh.shell = "/bin/askpass-luks";
}