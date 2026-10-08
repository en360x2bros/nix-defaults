{ lib, pkgs, ... }:
let
  # Login shell for the initrd SSH unlock: shows the pending systemd password
  # prompts (LUKS) and offers a rescue shell on CTRL+C.
  askpass = pkgs.writeScript "askpass-luks" ''
    #!/bin/sh
    echo "Press CTRL+C to enter shell..."
    trap '/bin/sh; exit' INT
    sleep 3
    trap - INT
    exec /bin/systemd-tty-ask-password-agent --watch
  '';
in
{
  # Shipped as a file in the initrd image instead of being written at runtime.
  # The former oneshot (askpass-luks-script, Before=cryptsetup.target with
  # default dependencies, i.e. also After=sysinit.target) formed an ordering
  # cycle with cryptsetup.target. systemd 260 broke the cycle by deleting that
  # job, /bin/askpass-luks never existed and sshd rejected root with
  # "shell /bin/askpass-luks does not exist" — remote unlock failed while the
  # console prompt still worked (ingress-fsn, 2026-10-08).
  boot.initrd.systemd.contents."/bin/askpass-luks".source = askpass;

  # Current option for systemd stage 1 (boot.initrd.network.ssh.shell is
  # deprecated there and only forwarded with a warning).
  boot.initrd.systemd.users.root.shell = "/bin/askpass-luks";
}
