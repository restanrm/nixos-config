{pkgs, ...}: {
  # install wtype to type chars for secrets
  environment.systemPackages = [pkgs.wtype];
  services.keyd = {
    enable = true;
    keyboards = {
      default = {
        ids = ["*"];
        settings = {
          main = {
            capslock = "overload(shift, esc)";
          };
          alt = {
            h = "left";
            j = "down";
            k = "up";
            l = "right";
          };
        };
      };
    };
  };
}
