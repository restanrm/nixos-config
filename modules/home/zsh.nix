{
  pkgs,
  config,
  context ? {
    work = false;
    hostType = "desktop";
  },
  ...
}: {
  imports =
    [
      ./zsh/common.nix
    ]
    ++ (
      if context.work
      then [./zsh/work.nix]
      else [./zsh/personal.nix]
    );

  # Additional shared configurations
  programs.zsh = {
    sessionVariables = {
      BELL_ADDRESS = "https://bell.restanrm.fr";
    };

    initExtra = ''
      # Setup PATH with all custom directories at runtime

      export PATH=$PATH:~/.nix-profile/bin
      export PATH=$PATH:~/.arkade/bin
      export PATH=$PATH:~/.krew/bin
      export PATH=$PATH:~/.cargo/bin
      export PATH=$PATH:~/.local/bin
      export PATH=$PATH:~/.local/share/pi-node/current/bin

      # Shared shell functions

      # Archive utility
      archive() {
          local success
          local remove_source=0
          if [ $# -eq 0 ]; then
        echo "USAGE : archive [options] files..."
        echo ""
        echo "\t-r,--remove\tremove source file"
        echo ""
          fi
          if [ "$1" = "-r" ] || [ "$1" = "--remove" ]; then
        remove_source=1
        shift
          fi
          while (( $# > 0 ))
          do
        tar cjvf "$1".tar.bz2 "$1"
        success=$?
        if [ $remove_source -eq 1 ] && [ $success -eq 0 ]; then
            rm -rf "$1"
        fi
        if [ $success -ne 0 ]; then
            echo "Erreur lors de l'opération d'archivage sur le fichier : $1"
            break
        fi
        shift
          done
      }

      # PDF utilities
      function pdftk() {
        docker run --rm -it -v $PWD:/data --workdir /data restanrm/docker-pdftk pdftk $@
      }

      pdfsplit() {
        gs -sDEVICE=pdfwrite -q -dNOPAUSE -dBATCH -sOutputFile="$4" -dFirstPage="$2" -dLastPage="$3" "$1"
      }

      pdfjoin() {
        gs -sDEVICE=pdfwrite -q -dNOPAUSE -sOutputFile="$1" -dBATCH $argv[2,$#]
      }

      # Kubernetes exec helper
      kex() {
        pod=$(kubectl get pod -o wide | grep Running | fzf --exit-0 --select-1 | awk '{print $1}')
        echo "kubectl exec -it ''${pod} -- $@"
        kubectl exec -it ''${pod} -- $@
      }

      # Git worktree management
      work() {
        local worktrees_dir=~/.wt
        local depth=1
        local args=$@

        # select the worktree
        local dir=$(fd . ''${worktrees_dir} --type d --max-depth ''${depth} --min-depth ''${depth} | xargs -I {} basename {} | fzf --query "''${args}" --print-query | tail -n 1)

        # return if $dir points nowhere
        if [ -z $dir ]; then
          return
        fi

        if [ -d ''${worktrees_dir}/$dir ]; then
          # if worktree already exist, cd into it
          cd ''${worktrees_dir}/$dir
          swaymsg rename workspace to "''${dir}"
        else
          # exit if we are not in a git repository
          git status 2>/dev/null 1>/dev/null
          if [ $? -ne 0 ]; then
            echo "Creating a worktree should be done in the original git directory"
            return
          fi

          local git_user=$(git remote -v | grep origin|awk -F':' '{print $2}' | awk '{print $1}' | awk -F'/' '{print $1}'| tail -n 1)
          local repo_name=$(git remote -v | grep origin|awk -F':' '{print $2}' | awk '{print $1}' | awk -F'/' '{print $2}'| xargs -I {} basename {} .git |tail -n 1)

          # select the main branch of the repository to tie the branch to
          local main_branch=$(git symbolic-ref refs/remotes/origin/HEAD | sed 's@^refs/remotes/origin/@@')

          git fetch -p
          git worktree add ''${worktrees_dir}/''${git_user}-''${repo_name}-''${dir} -b $dir origin/$dir
          if [ $? -ne 0 ]; then
            git worktree add ''${worktrees_dir}/''${git_user}-''${repo_name}-''${dir} -b $dir origin/''${main_branch} --no-track
            if [ $? -ne 0 ]; then
              git worktree add ''${worktrees_dir}/''${git_user}-''${repo_name}-''${dir} $dir
            fi
          fi
          cd ''${worktrees_dir}/''${git_user}-''${repo_name}-''${dir}
          swaymsg rename workspace to "''${git_user}-''${repo_name}-''${dir}"
        fi
      }

      endwork() {
        local worktrees_dir=~/.wt
        local depth=1
        local args=$@

        # exit if we are not in a git repository
        git status 2>/dev/null 1>/dev/null
        if [ $? -ne 0 ]; then
          echo "Removing a worktree should be done in a git directory"
          return
        fi

        if [ -z "''${args}" ]; then args="$(git rev-parse --abbrev-ref HEAD)"; fi
        local dir=$(fd . ''${worktrees_dir} --type d --max-depth ''${depth} --min-depth ''${depth} | xargs -I {} basename {} | fzf --print-query --query "$args" --exit-0 | tail -n 1)

        # return if $dir points nowhere
        if [ -z $dir ]; then
          return
        fi

        local git_user=$(git remote -v | grep origin|awk -F':' '{print $2}' | awk '{print $1}' | awk -F'/' '{print $1}'| tail -n 1)
        local repo_name=$(git remote -v | grep origin|awk -F':' '{print $2}' | awk '{print $1}' | awk -F'/' '{print $2}'| xargs -I {} basename {} .git |tail -n 1)

        if [ -d ''${worktrees_dir}/$dir ]; then
          pushd $(git worktree list | head -n 1| awk '{print $1}')
          git pull
          git worktree remove $dir --force
          git branch -D ''${dir##''${git_user}-''${repo_name}-}
          git remote update origin --prune
        fi
      }

      # Simple utilities
      setenv() { typeset -x "''${1}''${1:+=}''${(@)argv[2,$#]}" }
      freload() { while (( $# )); do; unfunction $1; autoload -U $1; shift; done }
      function calc() { awk "BEGIN { print $@ }" }
      cwc() { sed -e '/^\s*#/d' -e '/^\s*$/d' $* }
      sublocate() { locate $* | sed -n "/^''${PWD//\//\\/}/p"; }
      function f() {
        q="*$1*"
        find . -iname $q
      }

      # Helper functions for development workflow

      # Reload zsh configuration without logging out
      function zreload() {
        echo "🔄 Reloading zsh configuration..."
        exec zsh
      }

      # Rebuild NixOS and reload zsh
      function rebuild() {
        echo "🔨 Rebuilding NixOS configuration..."
        sudo nixos-rebuild switch --flake /home/nrm/nixos#hp-ara "$@" && {
          echo "✅ Rebuild successful!"
          echo "🔄 Reloading zsh..."
          sleep 1
          exec zsh
        } || echo "❌ Rebuild failed"
      }
    '';
  };

  # Additional packages needed for shell functions
  home.packages = with pkgs; [
    fd
    ripgrep
    git
    docker
    ghostscript
  ];
}
