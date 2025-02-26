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
    default = [];
    description = "List of SSH keys for the mgmt user.";
  };

  # Define the option `mgmt.passwordFile`
  options.mgmt.passwordFile = mkOption {
    type = types.path;
    description = ''
      Path to the encrypted password file for the mgmt user. 
      This option must be set when using the mgmt module.
    '';
  };

  # Use the option in the configuration
  config = {
    console.keyMap = "de";

    users.mutableUsers = false;

    users.users.mgmt = {
      isNormalUser = true;
      home = "/home/mgmt";
      description = "mgmt User";
      openssh.authorizedKeys.keys = config.mgmt.sshKeys;
      hashedPasswordFile = config.mgmt.passwordFile;
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
        mode = "normal";
        publickey = "invalid";
      };
    };
  };
}
