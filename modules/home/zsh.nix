{
  pkgs,
  config,
  ...
}: {
  programs.zsh = {
    enable = true;
    dotDir = "${config.xdg.configHome}/zsh";
    enableCompletion = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;
    shellAliases = {
      e = "nvim";
    };
    initContent = ''
      export PATH="$HOME/.local/bin:$PATH"
      eval "$(zoxide init zsh)"
      export PATH="/home/nrm/.local/share/pi-node/current/bin:$PATH"
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
