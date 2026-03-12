{ ... }:
{
  programs.neovim = {
    enable = true;
    defaultEditor = true; # Définit automatiquement EDITOR=nvim
  };

  home.sessionVariables = {
    EDITOR = "nvim";
    VISUAL = "nvim";
  };
}
