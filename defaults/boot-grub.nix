# use with EFI
{ ... }:
{
  config = {
    boot = {
      loader = {
        grub = {
          enable = true;
          efiSupport = true;
          efiInstallAsRemovable = true;
        };
      };
    };
  };
}