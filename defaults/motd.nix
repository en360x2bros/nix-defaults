{
  config,
  pkgs,
  lib,
  ...
}:

{
  config = {
    environment.systemPackages = with pkgs; [
      fancy-motd
    ];

    programs.bash.loginShellInit = ''
      if [[ -n "$SSH_CONNECTION" && -z "$SSH_AUTH_SOCK" && -t 0 && -z "$MOTD_SHOWN" ]]; then
        motd
        export MOTD_SHOWN=1
      fi
    '';
  };
}