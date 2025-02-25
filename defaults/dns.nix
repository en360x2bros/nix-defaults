{
  config,
  pkgs,
  lib,
  ...
}:

{
  config = {
    services.resolved = {
      enable = true;
      dnssec = "true";
      domains = [ "~." ];
      fallbackDns = [
        "8.8.4.4#eight.eight.four.four"
        "1.0.0.1#one.zero.zero.one"
      ];
      dnsovertls = "true";
    };

    networking.nameservers = [
      "1.1.1.1"
      "9.9.9.9"
      "2001:4860:4860::8888"
    ];
  };
}
