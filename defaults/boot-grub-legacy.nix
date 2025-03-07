# use with legacy BIOS
{ ... }:
{
  config = {
    boot = {
      loader = {
        grub = {
          enable = true;
          efiSupport = false;
          efiInstallAsRemovable = false;
        };
      };
    };
  };
}