{...}: {
  programs.neovim = {
    enable = true;
    defaultEditor = true; # Définit automatiquement EDITOR=nvim
  };

  home.sessionVariables = {
    EDITOR = "nvim";
    VISUAL = "nvim";
  };

  # Déploie la configuration nvim de façon déclarative
  # lazy-lock.json n'est pas géré ici car lazy.nvim doit pouvoir y écrire
  xdg.configFile."nvim/init.lua".source = ./assets/init.lua;
  xdg.configFile."nvim/lua".source = ./assets/lua;
  xdg.configFile."nvim/lazyvim.json".source = ./assets/lazyvim.json;
  xdg.configFile."nvim/stylua.toml".source = ./assets/stylua.toml;
}
