{pkgs, ...}: {
  # Work-specific zsh configuration
  programs.zsh = {
    # Work-specific aliases
    shellAliases = {
      ssht = "ssh -I /usr/lib/libykcs11.so fra1-test -t -- ";
      sshp = "ssh -I /usr/lib/libykcs11.so fra1-production -t -- ";
      bfra2 = "ssh -I /usr/lib/libykcs11.so fra2-production -t -- ";
      setclip = "wl-copy";
      getclip = "wl-paste";
      os = "openstack";
      insomnia = "bruno";
      longhorn = "kubectl -n longhorn-system port-forward svc/longhorn-frontend 8000:80 --context ";
    };

    # Work-specific environment variables
    sessionVariables = {
      VAULT_ADDR = "https://vault.delivery.sekoia.io";
      PULL_REGISTRY = "registry.sekoia.io";
      PUSH_REGISTRY = "registry.sekoia.io";
      RELEASE_ID = "latest";
      PLATFORM = "dev";
      PYTHON_KEYRING_BACKEND = "keyring.backends.null.Keyring";
      KUBECONFIG = "/home/nrm/dev/git/github.com/SekoiaLab/platform/resources/kubeconfig:/home/nrm/.kube/configs/restanrm.yaml";
      LOKI_ADDR = "https://loki-infra.delivery.sekoia.io";
      LOKI_USERNAME = "loki";
    };

    initExtra = ''
      # Work-specific functions

      # OBS workspace management
      function obs() {
        swaymsg rename workspace to 8
        /usr/bin/obs
      }

      # Search in platform repository
      function sf() {
        local args=$@
        cd $(fd . --type d | fzf --query "''${args} " --select-1 --exit-0)
      }

      # OpenStack context change function
      unset OS_CLOUD
      osctx () {
        local args=$1
        source <(gopass ls --flat | grep openrc.sh | wofi --show dmenu | xargs --no-run-if-empty gopass show -n)
      }

      # Vault login helper
      vlog () {
        vault token lookup 1>/dev/null 2>&1 || vault login -method=oidc 1>/dev/null 2>&1
      }

      # Horizon client wrapper
      function horizon-client() {
        unset MOZ_ENABLE_WAYLAND
        unset WAYLAND_DISPLAY
        /usr/bin/horizon-client
      }

      # Vault and switcher initialization
      func init_switch () {
        # if ping ok continue else stop
        ping -W1 -c1 8.8.8.8 >/dev/null 2>&1 || { echo "No internet connection"; return 1;}

        # if switch ok return else login to vault and restart
        switch . 2>&1 | grep -q "403. Errors" || return 0

        echo "Vault token expired. Authenticating to vault"

        # login to vault
        vault token lookup >/dev/null 2>&1 || vault login -method=oidc >/dev/null 2>&1

        switch . >/dev/null 2>&1 || (echo "Unknown error")
      }

      # Initialize switcher if available
      which scw >/dev/null && source <(scw autocomplete script shell=zsh)
      which switcher >/dev/null && {
        source <(switcher init zsh)
        source <(compdef _switcher switch)
        init_switch
      }
    '';
  };

  # Work-specific packages
  home.packages = with pkgs; [
    vault
    gopass
  ];
}
