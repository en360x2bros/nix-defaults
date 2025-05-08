{
  config,
  pkgs,
  lib,
  ...
}:

{
  config = {
    nixpkgs.config = {
      allowUnfree = true;
    };

    environment.systemPackages = with pkgs; [
      curl
      git
      fail2ban
      htop
      fastfetch
      zenith
      wget
      traceroute
      mtr
      dig
      jq
      rsync
      screen
      lsof
      ncdu
      tmux
      vim
      unzip
      nload
      bat
      fzf
      zoxide
      eza
      speedtest-go
      ookla-speedtest
      iperf
      fio
      geekbench
    ];
  };
}
