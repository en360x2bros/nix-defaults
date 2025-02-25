{
  config,
  pkgs,
  lib,
  ...
}:

let
  # Help function for options
  inherit (lib) mkOption types;
in
{
  # Define the option `mgmt.sshKeys`
  options.mgmt.sshKeys = mkOption {
    type = types.listOf types.str;
    default = [ ];
    description = "List of SSH keys for the mgmt user.";
  };

  # Use the option in the configuration
  config = {
    users.users.mgmt = {
      isNormalUser = true;
      home = "/home/mgmt";
      description = "mgmt User";
      openssh.authorizedKeys.keys = config.mgmt.sshKeys;
      extraGroups = [ "wheel" ];
      shell = pkgs.bash;
    };

    security.sudo.wheelNeedsPassword = false;

    services.openssh = {
      enable = true;
      settings = {
        PasswordAuthentication = false;
        PermitRootLogin = "no";
      };
    };

    # fail2ban for more security
    services.fail2ban = {
      enable = true;
      jails.sshd.settings = {
        mode = "aggressive";
        publickey = "invalid";
      };
    };
  };
}
