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
        describe-show-full-diff = true;
      };
      aliases = {
        tug = ["bookmark" "move" "--from" "heads(::@ & bookmarks())" "--to" "@"];
        tug- = ["bookmark" "move" "--from" "heads(::@- & bookmarks())" "--to" "@-"];
      };
      templates = {
        draft_commit_description = ''
          concat(
            builtin_draft_commit_description ++ "\n",
            indent("JJ: ",
              if(config("ui.describe-show-full-diff").as_boolean(),
                concat(
                  "Full diff of " ++ format_short_change_id(self.change_id()) ++ ":\n",
                  self.diff().git(),
                )
              ),
            ),
          )
        '';
      };
    };
  };
}
