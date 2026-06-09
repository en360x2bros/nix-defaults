{
  config,
  pkgs,
  lib,
  ...
}:

{
  config = {
    users.motd = "";

    systemd.services.fastfetch-motd = {
      enable = true;
      description = "Generate MOTD with fastfetch";
      serviceConfig = {
        ExecStart = ''${pkgs.bash}/bin/sh -c "${pkgs.fastfetch}/bin/fastfetch --logo sulin --config /etc/fastfetch/config.jsonc --pipe false > /etc/motd"'';
        Type = "oneshot";
      };
    };

    systemd.timers.fastfetch-motd = {
      description = "Run fastfetch MOTD generation every minute";
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnCalendar = "*:0/1";
        Persistent = true;
      };
    };

    # Konfigurationsdatei bereitstellen
    environment.etc."fastfetch/config.jsonc" = {
      text = ''
        {
            "$schema": "https://github.com/fastfetch-cli/fastfetch/raw/dev/doc/json_schema.json",
            "display": {
                "bar": {
                  "char": {
                    "elapsed": "=",
                    "total": "-",
                  },
                  "width": 15
                },
                "percent": {
                  "type": 2
                }
            },
            "modules": [
                { "type": "os", "key": "OS" },
                { "type": "kernel", "key": "Kernel" },
                { "type": "uptime", "key": "Uptime" },
                { "type": "datetime" },
                { "type": "cpu", "key": "CPU", "showPeCoreCount": true, "temp": true },
                { "type": "cpuusage" },
                { "type": "break" },
                { "type": "physicalmemory", "key": "RAM" },
                { "type": "memory", "key": "RAM Usage" },
                { "type": "break" },
                { "type": "disk", "folders": "/" },
                { "type": "btrfs" },
                { "type": "zpool" },
                { "type": "swap" },
                { "type": "netio" },
                { "type": "physicaldisk", "temp": true },
                { "type": "localip", "showIpv6": true, "showSpeed": false, "showMtu": false, "showAllIps": true },
                { "type": "publicip", "timeout": 1000 },
                { "type": "colors", "paddingLeft": 10, "symbol": "circle" }
            ]
        }
      '';
      mode = "0644";
    };

    # No reliable server-side MOTD on this setup: services.openssh PrintMotd is
    # a no-op under UsePAM=yes, and sshd does not relay pam_motd's session
    # output to the client on this OpenSSH build. So print it from the login
    # shell, but gated cleanly:
    #   - $SSH_CONNECTION  → only on real SSH logins, never on su -/sudo su -
    #   - $_MOTD_SHOWN     → only once, even if login init is sourced twice
    #   - TERM_PROGRAM≠Warp→ Warp renders the MOTD itself; avoid double display
    programs.bash.loginShellInit = ''
      if [ -z "$_MOTD_SHOWN" ] && [ -n "$SSH_CONNECTION" ] && [[ $- == *i* ]] \
         && [ "$TERM_PROGRAM" != "WarpTerminal" ] && [ -r /etc/motd ]; then
        cat /etc/motd
        export _MOTD_SHOWN=1
      fi
    '';

  };
}
