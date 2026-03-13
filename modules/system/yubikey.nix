{pkgs, ...}: {
  # for yubikey
  services.udev.packages = [pkgs.yubikey-personalization];
  # daemon to talk to smartcards (including yubikey with PIV)
  services.pcscd = {
    enable = true;
    # plugin for USB tokens
    plugins = [pkgs.ccid];
  };
}
