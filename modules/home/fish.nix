{pkgs, ...}: {
  programs.fish = {
    enable = true;
    functions = {
      vault = ''
        set --local output (command vault $argv 2>&1)
        set --local status_code $status_code
        if echo $output | string  match -q "*Code: 403. Errors"
          or test $status_code -eq 2

          echo (set_color yellow)"403 Forbidden detected. Attempting OIDC login..."(set_color normal)

          if command vault login -method oidc 1>/dev/null 2>&1
            echo (set_color green)"Login successful. Retrying original command..."(set_color normal)
            command vault $argv
          else
            echo (set_color red)"Login failed. Please check your credentials."(set_color normal)
            return 1
          end
        else
          string join \n -- $output
          return $status_code
        end
      '';
    };
  };
}
