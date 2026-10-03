{pkgs, ...}: let
  bwmenu = pkgs.writeShellScriptBin "bwmenu" ''
    set -euo pipefail
    umask 077
    unset BW_SESSION BW_PASSWORD

    server_url="https://vault.bitwarden.eu"
    auto_lock="''${BW_AUTO_LOCK:-86400}"
    cache_dir="''${XDG_CACHE_HOME:-$HOME/.cache}/bwmenu"
    items_file="$cache_dir/logins.gpg"

    error() {
      printf '%s\n' "$1" >&2
      ${pkgs.rofi}/bin/rofi -e "$1" >/dev/null 2>&1 || true
    }

    sync_only=0
    while [ "$#" -gt 0 ]; do
      case "$1" in
        --auto-lock)
          [ "$#" -ge 2 ] || { error 'Missing value for --auto-lock'; exit 2; }
          auto_lock="$2"
          shift 2
          ;;
        --auto-lock=*) auto_lock="''${1#*=}"; shift ;;
        --sync) sync_only=1; shift ;;
        *) error "Unknown bwmenu argument: $1"; exit 2 ;;
      esac
    done

    [ -n "$auto_lock" ] || { error 'Bitwarden auto-lock must be seconds from 0 to 86400'; exit 2; }
    case "$auto_lock" in
      (*[!0-9]*) error 'Bitwarden auto-lock must be seconds from 0 to 86400'; exit 2 ;;
    esac
    while [ "''${#auto_lock}" -gt 1 ] && [ "''${auto_lock:0:1}" = 0 ]; do
      auto_lock="''${auto_lock#0}"
    done
    if [ "''${#auto_lock}" -gt 5 ] || [ "$auto_lock" -gt 86400 ]; then
      auto_lock=86400
    fi
    auto_lock=$((10#$auto_lock))

    [ -n "''${XDG_RUNTIME_DIR:-}" ] && [ -d "$XDG_RUNTIME_DIR" ] || {
      error 'Bitwarden needs an owner-only XDG_RUNTIME_DIR'; exit 1;
    }
    runtime_owner="$(${pkgs.coreutils}/bin/stat -c %u "$XDG_RUNTIME_DIR" 2>/dev/null)" || {
      error 'Cannot verify XDG_RUNTIME_DIR ownership'; exit 1;
    }
    [ "$runtime_owner" = "$(${pkgs.coreutils}/bin/id -u)" ] || {
      error 'XDG_RUNTIME_DIR is not owned by the current user'; exit 1;
    }
    runtime_dir="$XDG_RUNTIME_DIR/bwmenu"
    session_file="$runtime_dir/session"
    mkdir -p "$runtime_dir" "$cache_dir" || { error 'Cannot create Bitwarden cache directories'; exit 1; }
    chmod 700 "$runtime_dir" "$cache_dir" || { error 'Cannot secure Bitwarden cache directories'; exit 1; }
    # Older versions kept this session key in persistent XDG_CACHE_HOME.
    rm -f "$cache_dir/session"

    bw() {
      ${pkgs.bitwarden-cli}/bin/bw "$@"
    }

    now() {
      ${pkgs.coreutils}/bin/date +%s
    }

    read_cached_session() {
      local session session_ts current_time age extra
      [ -s "$session_file" ] || return 1
      [ "$(${pkgs.coreutils}/bin/stat -c %u "$session_file" 2>/dev/null)" = "$(${pkgs.coreutils}/bin/id -u)" ] || return 1
      chmod 600 "$session_file" || return 1
      IFS=' ' read -r session session_ts extra < "$session_file" || return 1
      if [ -z "$session_ts" ]; then rm -f "$session_file"; return 1; fi
      case "$session_ts" in
        (*[!0-9]*) rm -f "$session_file"; return 1 ;;
      esac
      if [ "''${#session_ts}" -gt 10 ]; then rm -f "$session_file"; return 1; fi
      session_ts=$((10#$session_ts))
      [ -n "$session" ] && [ -z "''${extra:-}" ] || { rm -f "$session_file"; return 1; }
      current_time="$(now)"
      age=$((current_time - session_ts))
      if [ "$age" -ge 0 ] && [ "$age" -lt "$auto_lock" ]; then
        printf '%s\n' "$session"
        return 0
      fi
      rm -f "$session_file"
      return 1
    }

    save_session() {
      local tmp_file
      tmp_file="$(mktemp "$runtime_dir/.session.XXXXXX")" || { error 'Cannot cache Bitwarden session'; return 1; }
      if ! printf '%s %s\n' "$1" "$2" > "$tmp_file" || ! chmod 600 "$tmp_file" || ! mv -f "$tmp_file" "$session_file"; then
        rm -f "$tmp_file"
        error 'Cannot cache Bitwarden session'
        return 1
      fi
    }

    configure_server() {
      local status="$1" current_server
      if ! current_server="$(bw config server 2>/dev/null)"; then
        error 'Cannot read the Bitwarden server configuration'; return 1
      fi
      [ "$current_server" = "$server_url" ] && return 0
      if [ "$status" != unauthenticated ]; then
        error "Bitwarden server mismatch: logged-in server is '$current_server'; expected '$server_url'"
        return 1
      fi
      bw config server "$server_url" >/dev/null 2>&1 || {
        error 'Cannot configure the Bitwarden server'; return 1;
      }
    }

    authenticate_session() {
      local status_json status session master_password
      if ! status_json="$(bw status 2>/dev/null)"; then
        error 'Cannot read Bitwarden login status'; return 1
      fi
      if ! status="$(printf '%s\n' "$status_json" | ${pkgs.jq}/bin/jq -r '.status // empty' 2>/dev/null)"; then
        error 'Cannot parse Bitwarden login status'; return 1
      fi
      case "$status" in
        unauthenticated|locked|unlocked) ;;
        *) error 'Bitwarden returned an unknown login status'; return 1 ;;
      esac
      configure_server "$status" || return 1
      case "$status" in
        unauthenticated)
          sso_dir="$(mktemp -d "$runtime_dir/.sso.XXXXXX")" || { error 'Cannot create temporary SSO files'; return 1; }
          trap 'rm -rf -- "$sso_dir"' EXIT
          trap 'exit 129' HUP
          trap 'exit 130' INT
          trap 'exit 143' TERM
          ${pkgs.alacritty}/bin/alacritty -e ${pkgs.bash}/bin/bash -c '
            umask 077
            BW_NOINTERACTION=false ${pkgs.bitwarden-cli}/bin/bw login --sso --raw >"$1"
            result=$?
            printf "%s\\n" "$result" >"$2"
            if [ "$result" -ne 0 ]; then
              printf "\\nBitwarden SSO login failed (exit %s). Press Enter to close." "$result" >&2
              IFS= read -r _
            fi
            exit 0
          ' bwmenu-sso "$sso_dir/session" "$sso_dir/status" || true
          auth_result=""
          if [ -r "$sso_dir/status" ]; then
            IFS= read -r auth_result < "$sso_dir/status" || true
          fi
          if [ "$auth_result" = 0 ]; then
            session="$(${pkgs.coreutils}/bin/cat "$sso_dir/session")" || { error 'Cannot read the SSO session'; return 1; }
          fi
          ${pkgs.coreutils}/bin/rm -rf -- "$sso_dir"
          sso_dir=""
          trap - EXIT HUP INT TERM
          if [ "$auth_result" != 0 ]; then
            [ -n "$auth_result" ] || return 2
            error 'Bitwarden SSO login failed'; return 1
          fi
          ;;
        locked|unlocked) session="" ;;
        *) error 'Bitwarden returned an unknown login status'; return 1 ;;
      esac

      if [ -z "$session" ]; then
        if ! master_password="$(${pkgs.rofi}/bin/rofi -dmenu -password -p 'Bitwarden master password')"; then
          return 2
        fi
        [ -n "$master_password" ] || return 2
        if ! session="$(BW_NOINTERACTION=true BW_PASSWORD="$master_password" bw unlock --raw --passwordenv BW_PASSWORD 2>/dev/null)"; then
          unset master_password
          error 'Bitwarden unlock failed'
          return 1
        fi
        unset master_password
      fi
      [ -n "$session" ] || { error 'Bitwarden did not return a session'; return 1; }
      printf '%s\n' "$session"
    }

    decrypt_items() {
      local session="$1"
      [ -s "$items_file" ] || return 1
      ${pkgs.gnupg}/bin/gpg --quiet -d --batch --yes --pinentry-mode loopback --passphrase-fd 3 "$items_file" 3<<< "$session"
    }

    sync_items() {
      local session="$1" tmp_file
      if ! BW_SESSION="$session" bw sync >/dev/null 2>&1; then
        error 'Bitwarden sync failed; the cached vault was kept'
        return 1
      fi
      tmp_file="$(mktemp "$cache_dir/.logins.XXXXXX")" || {
        error 'Cannot create an encrypted Bitwarden cache'; return 1;
      }
      if ! BW_SESSION="$session" bw list items 2>/dev/null \
        | ${pkgs.gnupg}/bin/gpg --symmetric --batch --yes --pinentry-mode loopback --passphrase-fd 3 --cipher-algo AES256 -o "$tmp_file" 3<<< "$session"; then
        rm -f "$tmp_file"
        error 'Cannot refresh the encrypted Bitwarden cache; the old cache was kept'
        return 1
      fi
      if ! mv -f "$tmp_file" "$items_file"; then
        rm -f "$tmp_file"
        error 'Cannot replace the encrypted Bitwarden cache; the old cache was kept'
        return 1
      fi
    }

    menu() {
      local prompt="$1" message="$2"
      ${pkgs.rofi}/bin/rofi \
        -dmenu \
        -i \
        -matching fuzzy \
        -format i \
        -p "$prompt" \
        -mesg "$message" \
        -kb-custom-1 Alt+y \
        -kb-custom-2 Alt+u \
        -kb-custom-3 Alt+o \
        -kb-custom-4 Alt+l \
        -kb-custom-5 Alt+g
    }

    choose_url() {
      local json="$1" urls selected_url
      urls="$(printf '%s\n' "$json" | ${pkgs.jq}/bin/jq -r '.[] | .login.uris[]?.uri' | ${pkgs.coreutils}/bin/sort -u)"
      [ -n "$urls" ] || return 1
      selected_url="$(printf '%s\n' "$urls" | ${pkgs.rofi}/bin/rofi -dmenu -i -matching fuzzy -p URL)" || return 1
      [ -n "$selected_url" ] || return 1
      printf '%s\n' "$selected_url"
    }

    choose_folder() {
      local session="$1" folders_json choices selected_folder folder_id idx line
      if ! folders_json="$(BW_SESSION="$session" bw list folders 2>/dev/null)"; then
        error 'Cannot list Bitwarden folders'
        return 1
      fi
      choices="$(printf 'No Folder\t__ROOT__\n%s\n' "$(printf '%s\n' "$folders_json" | ${pkgs.jq}/bin/jq -r '.[] | [.name // "", .id] | @tsv')")"
      selected_folder="$(printf '%s\n' "$choices" | ${pkgs.rofi}/bin/rofi -dmenu -i -matching fuzzy -p Folder -format i)" || return 1
      [ -n "$selected_folder" ] || return 1
      folder_id=""
      idx=0
      while IFS= read -r line; do
        if [ "$idx" -eq "$selected_folder" ]; then
          folder_id="$(printf '%s' "$line" | ${pkgs.coreutils}/bin/cut -f2)"
          break
        fi
        idx=$((idx + 1))
      done <<< "$choices"
      [ "$folder_id" = '__ROOT__' ] && folder_id=""
      printf '%s\n' "$folder_id"
    }

    filter_by_url() {
      local json="$1" url="$2"
      printf '%s\n' "$json" | ${pkgs.jq}/bin/jq -c --arg url "$url" '[.[] | select(.type == 1 and any(.login.uris[]?; .uri == $url))]'
    }

    filter_by_folder() {
      local json="$1" folder_id="$2"
      printf '%s\n' "$json" | ${pkgs.jq}/bin/jq -c --arg folder_id "$folder_id" '[.[] | select(.type == 1 and ((.folderId // "") == $folder_id))]'
    }

    current_session="$(read_cached_session || true)"
    if [ "$sync_only" -eq 1 ]; then
      [ -n "$current_session" ] || { error 'No unexpired Bitwarden session; open bwmenu to unlock before syncing'; exit 1; }
      sync_items "$current_session"
      exit $?
    fi

    items_json=""
    if [ -n "$current_session" ]; then
      items_json="$(decrypt_items "$current_session" 2>/dev/null || true)"
    fi
    new_session=0
    session_ts=""
    if [ -z "$items_json" ]; then
      if [ -z "$current_session" ]; then
        if current_session="$(authenticate_session)"; then
          new_session=1
          session_ts="$(now)"
        else
          auth_result=$?
          [ "$auth_result" -eq 2 ] && exit 0
          exit 1
        fi
      fi
      if ! sync_items "$current_session"; then
        exit 1
      fi
      if ! items_json="$(decrypt_items "$current_session" 2>/dev/null)"; then
        error 'Cannot decrypt the Bitwarden cache'
        exit 1
      fi
      if [ "$new_session" -eq 1 ]; then
        save_session "$current_session" "$session_ts" || exit 1
      fi
    fi

    view_json="$(printf '%s\n' "$items_json" | ${pkgs.jq}/bin/jq -c '[.[] | select(.type == 1)]')"
    message="Alt+y sync | Alt+u urls | Alt+o folders | Alt+l lock | Alt+g totp"

    selected_item_id() {
      local selected_index="$1" choices="$2" idx=0 line
      while IFS= read -r line; do
        if [ "$idx" -eq "$selected_index" ]; then
          printf '%s\n' "$(printf '%s' "$line" | ${pkgs.coreutils}/bin/cut -f3)"
          return 0
        fi
        idx=$((idx + 1))
      done <<< "$choices"
      return 1
    }

    while true; do
      choices="$(printf '%s\n' "$view_json" | ${pkgs.jq}/bin/jq -r '.[] | [.name // "", (.login.username // ""), .id] | @tsv')"
      [ -n "$choices" ] || exit 0

      code=0
      selected_index="$(printf '%s\n' "$choices" | menu 'Bitwarden' "$message")" || code=$?
      case "$code" in
        0)
          [ -n "$selected_index" ] || exit 0
          item_id="$(selected_item_id "$selected_index" "$choices")" || exit 0
          password="$(printf '%s\n' "$view_json" | ${pkgs.jq}/bin/jq -r --arg id "$item_id" '.[] | select(.id == $id) | .login.password // empty')"
          [ -n "$password" ] || exit 0
          if ! printf '%s' "$password" | ${pkgs.wl-clipboard}/bin/wl-copy; then
            error 'Could not copy the selected password'
            exit 1
          fi
          exit 0
          ;;
        10)
          if sync_items "$current_session"; then
            if refreshed_items="$(decrypt_items "$current_session" 2>/dev/null)"; then
              items_json="$refreshed_items"
              view_json="$(printf '%s\n' "$items_json" | ${pkgs.jq}/bin/jq -c '[.[] | select(.type == 1)]')"
            else
              error 'Cannot decrypt the refreshed Bitwarden cache'
            fi
          fi
          ;;
        11)
          url="$(choose_url "$view_json")" || continue
          view_json="$(filter_by_url "$view_json" "$url")"
          ;;
        12)
          folder_id="$(choose_folder "$current_session")" || continue
          view_json="$(filter_by_folder "$view_json" "$folder_id")"
          ;;
        13)
          rm -f "$session_file"
          if ! BW_SESSION="$current_session" bw lock >/dev/null 2>&1; then
            error 'Bitwarden lock failed'
            exit 1
          fi
          exit 0
          ;;
        14)
          [ -n "$selected_index" ] || continue
          item_id="$(selected_item_id "$selected_index" "$choices")" || continue
          if ! totp="$(BW_SESSION="$current_session" bw get totp "$item_id" 2>/dev/null)"; then
            error 'Could not retrieve the selected Bitwarden TOTP'
            continue
          fi
          [ -n "$totp" ] || continue
          if ! printf '%s' "$totp" | ${pkgs.wl-clipboard}/bin/wl-copy; then
            error 'Could not copy the selected Bitwarden TOTP'
            exit 1
          fi
          exit 0
          ;;
        *) exit 0 ;;
      esac
    done
  '';
in {
  home.packages = [
    bwmenu
    pkgs.bitwarden-cli
  ];

  home.file.".local/share/applications/bwmenu.desktop".text = ''
    [Desktop Entry]
    Type=Application
    Name=Bitwarden Menu
    Comment=Browse and copy passwords from your Bitwarden vault
    Exec=bwmenu
    Terminal=false
    Categories=Utility;Security;
  '';
}
