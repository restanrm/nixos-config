{...}: {
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
      remotes.origin = {
        "auto-track-created-bookmarks" = "*";
      };
      ui = {
        default-command = "log";
      };
      aliases = {
        tug = ["bookmark" "move" "--from" "heads(::@ & bookmarks())" "--to" "@"];
        tug- = ["bookmark" "move" "--from" "heads(::@- & bookmarks())" "--to" "@-"];
      };
    };
  };
}
