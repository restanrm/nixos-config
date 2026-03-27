{...}: {
  services.keyd = {
    enable = true;
    keyboards = {
      default = {
        ids = ["*"];
        settings = {
          main = {
            capslock = "overload(capslock, esc)";
          };
          alt = {
            h = "left";
            j = "down";
            k = "up";
            l = "right";
          };
          # capslock = {
          #   h = "left";
          #   j = "down";
          #   k = "up";
          #   l = "right";
          #   # secrets for tha1
          #   # s = "macro(S0155656)";
          # };
        };
      };
    };
  };
}
