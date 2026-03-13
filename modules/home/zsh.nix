{pkgs, ...}: {
  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;
    shellAliases:  = {
        e = nvim;
      };
  };

  # Activation du plugin Oh My Zsh (optionnel mais recommandé)
  programs.zsh.oh-my-zsh = {
    enable = true;
    plugins = ["git" "sudo" "docker" "kubectl"];
    theme = "robbyrussell";
  };

}
