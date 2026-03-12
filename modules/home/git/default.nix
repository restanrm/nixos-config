{ ... }:
{
  programs.git = {
    enable = true;
    userName = "Adrien Raffin";
    userEmail = "adrien.raffin@sekoia.io";
    extraConfig = {
      init.defaultBranch = "main";
      pull.rebase = true;
    };
  };

  programs.jujutsu = {
    enable = true;
    settings = {
      user = {
        name = "Adrien Raffin";
        email = "adrien.raffin@sekoia.io";
      };
      ui = {
        default-command = "log";
      };
    };
  };
}
