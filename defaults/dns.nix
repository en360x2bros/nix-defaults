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
        "2001:4860:4860::8844#eight.eight.four.four"
      ];
      dnsovertls = "true";
    };

    networking.nameservers = lib.mkDefault [
      "1.1.1.1"
      "9.9.9.9"
      "2001:4860:4860::8888"
    ];
  };
}
