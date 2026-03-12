{...}: {
  programs.alacritty = {
    enable = true;
    settings = {
      window.opacity = 0.80;
      font = {
        size = 9;
        normal = {
          family = "NotoSansM Nerd Font";
          style = "Regular";
        };
      };
    };
  };
}
