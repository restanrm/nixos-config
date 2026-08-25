{
  pkgs,
  config,
  ...
}: {
  # Shared zsh configuration across all contexts
  programs.zsh = {
    enable = true;
    dotDir = "${config.xdg.configHome}/zsh";
    enableCompletion = true;
    autosuggestion = {
      enable = true;
      highlight = "fg=#808080";
    };
    syntaxHighlighting.enable = true;
    historySubstringSearch.enable = true;

    oh-my-zsh = {
      enable = true;
      plugins = [
        "git"
        "jump"
        "pass"
        "ssh-agent"
        "extract"
        "kube-ps1"
        "direnv"
      ];
      theme = "robbyrussell";
    };

    # Common environment variables
    sessionVariables = {
      ZSH_CACHE_DIR = "$HOME/.cache/zsh";
      EDITOR = "nvim";
      GOPATH = "$HOME/dev/go";
      MANSECT = "2:3:9:8:1:5:4:7:6:n";
      GIT_PAGER = "less";
      TERM = "xterm";
      LIBVA_DRIVER_NAME = "iHD";
      MOZ_ENABLE_WAYLAND = "1";
      FZF_DEFAULT_COMMAND = "rg -g \"\" --files";
      K9S_FEATURE_GATE_NODE_SHELL = "true";
    };

    # Common aliases across all contexts
    shellAliases = {
      # Editor
      vim = "nvim";
      e = "$EDITOR";

      # Basic navigation
      c = "clear";
      s = "sudo";
      j = "jobs";
      pu = "pushd";
      po = "popd";
      d = "dirs -v";
      h = "history";

      # Git
      g = "git";

      # Utilities
      top = "htop";
      ls = "ls --color=auto";
      grep = "grep --color=auto";
      ll = "ls -lh";
      la = "ls -a";
      lla = "ll -a";
      lsd = "ls -ld *(-/DN)";
      lsa = "ls -ld .*";
      l = "ls -CF";
      p = "ps -A f -o user,pid,priority,ni,pcpu,pmem,args";
      wcat = "wget -q -O -";
      nh = "unset HISTFILE";

      # mkdir
      mkdir = "nocorrect mkdir";

      # Kubernetes
      k = "kubectl";
      kns = "kubens";
      kctx = "kubectx";
      ks = "kubectl --namespace kube-system";
      ko = "kubectl get pods -A -o wide | egrep -vi 'running|completed'";

      # File suffix aliases
      pdf = "evince";
    };

    # Global aliases (can be used anywhere in the command)
    shellGlobalAliases = {
      L = "less";
      M = "more";
      H = "head";
      T = "tail";
    };

    # Init script - runs after oh-my-zsh is loaded
    initExtra = ''
      # Create tmp directory for user
      if [ ! -d /tmp/$USER ]; then
        mkdir /tmp/$USER 2>/dev/null
      fi

      # SSH Agent configuration
      zstyle :omz:plugins:ssh-agent agent-forwarding yes

      # Prompt customization
      PROMPT=$PROMPT'$(kube_ps1) (%D{%y-%m-%dT%H:%M:%S%z}) '

      # ZSH Options
      limit -s coredumpsize 0
      umask 0002

      # General
      setopt ALWAYS_TO_END BASH_AUTO_LIST NO_BEEP CLOBBER
      setopt AUTO_CD MULTIOS CORRECT
      setopt completealiases

      # Job Control
      setopt CHECK_JOBS NO_HUP

      # History
      setopt INC_APPEND_HISTORY EXTENDED_HISTORY HIST_IGNORE_DUPS HIST_FIND_NO_DUPS
      setopt HIST_EXPIRE_DUPS_FIRST HIST_REDUCE_BLANKS HIST_SAVE_NO_DUPS
      HISTSIZE=10000
      SAVEHIST=10000
      HISTFILE=~/.history
      DIRSTACKSIZE=20

      # Stay compatible to sh and IFS
      setopt SH_WORD_SPLIT

      setopt notify globdots pushdtohome
      setopt recexact longlistjobs
      setopt autoresume pushdsilent
      setopt extendedglob autopushd pushdminus rcquotes mailwarning pushd_ignore_dups
      unsetopt BG_NICE HUP autoparamslash list_ambiguous

      # Don't expand files matching
      fignore=(\~ .old .pro)

      # Colored completion
      zstyle ':completion:*:default' list-colors ''${(s.:.)LS_COLORS}

      # Key bindings
      bindkey -e
      bindkey "^u" vi-kill-line
      bindkey "^[[3~" delete-char
      bindkey '\eq' push-line-or-edit
      bindkey '^p' history-search-backward
      bindkey "^[[3A" history-beginning-search-backward
      bindkey "^[[3B" history-beginning-search-forward
      bindkey -s '^B' " &\n"

      # Terminal-specific settings
      case "$TERM" in
        linux)
          bindkey '\e[1~' beginning-of-line
          bindkey '\e[4~' end-of-line
          bindkey '\e[3~' delete-char
          bindkey '\e[2~' overwrite-mode
          ;;
        screen)
          bindkey '\e[1~' beginning-of-line
          bindkey '\e[4~' end-of-line
          bindkey '\e[3~' delete-char
          bindkey '\e[2~' overwrite-mode
          bindkey '\e[7~' beginning-of-line
          bindkey '\e[8~' end-of-line
          bindkey '\eOc' forward-word
          bindkey '\eOd' backward-word
          bindkey '\e[3~' backward-delete-char
          ;;
        rxvt*)
          bindkey '\e[7~' beginning-of-line
          bindkey '\e[8~' end-of-line
          bindkey '\eOc' forward-word
          bindkey '\eOd' backward-word
          bindkey '\e[3~' delete-char
          bindkey '\e[2~' overwrite-mode
          ;;
        xterm*)
          bindkey "\e[1~" beginning-of-line
          bindkey "\e[4~" end-of-line
          bindkey '\e[3~' delete-char
          bindkey '\e[2~' overwrite-mode
          ;;
        sun)
          bindkey '\e[214z' beginning-of-line
          bindkey '\e[220z' end-of-line
          bindkey '^J' delete-char
          bindkey '^H' backward-delete-char
          bindkey '\e[247z' overwrite-mode
          ;;
      esac

      # Completion system
      autoload -Uz compinit
      compinit

      zstyle ':completion:*' completer _expand _complete _approximate
      zstyle ':completion:*' format '%d:'
      zstyle ':completion:*' group-name ""
      zstyle ':completion:*' list-colors ''${(s.:.)LS_COLORS}
      zstyle ':completion:*:sudo:*' command-path /usr/local/sbin /usr/local/bin /usr/sbin /usr/bin /sbin /bin
      zstyle ':completion:*' auto-description 'specify: %d'
      zstyle ':completion:*' completer _expand _complete _correct _approximate
      zstyle ':completion:*' format 'Completing %d'
      zstyle ':completion:*' group-name ""
      zstyle ':completion:*' list-prompt %SAt %p: Hit TAB for more, or the character to insert%s
      zstyle ':completion:*' matcher-list "" 'm:{a-z}={A-Z}' 'm:{a-zA-Z}={A-Za-z}' 'r:|[._-]=* r:|=* l:|=*'
      zstyle ':completion:*' menu select=long
      zstyle ':completion:*' select-prompt %SScrolling active: current selection at %p%s
      zstyle ':completion:*' use-compctl false
      zstyle ':completion:*' verbose true
      zstyle ':completion:*:*:kill:*:processes' list-colors '=(#b) #([0-9]#)*=0=01;31'
      zstyle ':completion:*:kill:*' command 'ps -u $USER -o pid,%cpu,tty,cputime,cmd'

      # Load modules
      zmodload zsh/complist
      zmodload -a zsh/stat stat
      zmodload -a zsh/zpty zpty
      zmodload -ap zsh/mapfile mapfile

      autoload -Uz vcs_info

      # FZF integration
      [ -f /usr/share/fzf/key-bindings.zsh ] && source /usr/share/fzf/key-bindings.zsh
      [ -f /usr/share/fzf/completion.zsh ] && source /usr/share/fzf/completion.zsh

      # Kubectl completion
      which kubectl >/dev/null && source <(kubectl completion zsh)
      which minikube >/dev/null && source <(minikube completion zsh)

      # zoxide init
      eval "$(zoxide init zsh)"

      # Disable flow control
      stty -ixon

      # Auto-start Hyprland on TTY1
      if [ "''$(tty)" = "/dev/tty1" ]; then
        exec start-hyprland
      fi
    '';
  };

  # Install zsh plugins
  home.packages = with pkgs; [
    zoxide
    fzf
    kubectl
  ];
}
