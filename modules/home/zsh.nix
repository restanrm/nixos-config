{pkgs, ...}: {
  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;
    shellAliases = {
      e = "nvim";
    };
    initContent = ''
      eval "$(zoxide init zsh)"
    '';
    sessionVariables = {
      VAULT_ADDR = "https://vault.delivery.sekoia.io";
    };
  };

  # Activation du plugin Oh My Zsh (optionnel mais recommandé)
  programs.zsh.oh-my-zsh = {
    enable = true;
    plugins = ["git" "sudo" "docker" "kubectl"];
    theme = "robbyrussell";
  };
}
