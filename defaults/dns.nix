{ lib, options, ... }:

let
  hasResolvedSettings = lib.hasAttrByPath [ "services" "resolved" "settings" "Resolve" ] options;
in
{
  config = lib.mkMerge [
    {
      services.resolved.enable = true;

      networking.nameservers = lib.mkDefault [
        "1.1.1.1"
        "9.9.9.9"
        "2001:4860:4860::8888"
      ];
    }

    (lib.mkIf hasResolvedSettings {
      services.resolved.settings.Resolve = {
        DNSSEC = "false"; # important to prevent dns issues
        Domains = [ "~." ];
        FallbackDNS = [
          "8.8.4.4#eight.eight.four.four"
          "1.0.0.1#one.zero.zero.one"
          "2001:4860:4860::8844#eight.eight.four.four"
        ];
        DNSOverTLS = "false"; # important to prevent dns issues
      };
    })

    (lib.mkIf (!hasResolvedSettings) {
      services.resolved = {
        dnssec = "false"; # important to prevent dns issues
        domains = [ "~." ];
        fallbackDns = [
          "8.8.4.4#eight.eight.four.four"
          "1.0.0.1#one.zero.zero.one"
          "2001:4860:4860::8844#eight.eight.four.four"
        ];
        dnsovertls = "false"; # important to prevent dns issues
      };
    })
  ];
}
