{pkgs, ...}: let
  bwmenu = pkgs.writeShellScriptBin "bwmenu" ''
        set -euo pipefail
        umask 077

        server_url="https://vault.bitwarden.eu"
        auto_lock="''${BW_AUTO_LOCK:-86400}"
        cache_dir="''${XDG_CACHE_HOME:-$HOME/.cache}/bwmenu"
        session_file="$cache_dir/session"
        items_file="$cache_dir/logins.gpg"

        mkdir -p "$cache_dir"

        bw() {
          ${pkgs.bitwarden-cli}/bin/bw "$@"
        }

        now() {
          ${pkgs.coreutils}/bin/date +%s
        }

        read_cached_session() {
          [ -s "$session_file" ] || return 1
          read -r session session_ts < "$session_file" || return 1
          case "$session_ts" in
            (*[!0-9]*) return 1 ;;
          esac
          [ -n "$session_ts" ] || return 1
          current_time="$(now)"
          if [ "$auto_lock" = "-1" ] || [ "$((current_time - session_ts))" -lt "$auto_lock" ]; then
            printf '%s\n' "$session"
            return 0
          fi
          return 1
        }

        authenticate_session() {
          bw config server "$server_url" >/dev/null 2>&1 || true
          status="$(bw status 2>/dev/null | ${pkgs.jq}/bin/jq -r '.status // empty' 2>/dev/null || true)"
          if [ "$status" = "unauthenticated" ] || [ -z "$status" ]; then
            session="$(bw login --sso --raw 2>/dev/null | ${pkgs.coreutils}/bin/tail -n1)"
          else
            master_password="$(${pkgs.rofi}/bin/rofi -dmenu -password -p 'Bitwarden master password')" || exit 0
            [ -z "$master_password" ] && exit 0
            session="$(BW_PASSWORD="$master_password" bw unlock --raw --passwordenv BW_PASSWORD 2>/dev/null | ${pkgs.coreutils}/bin/tail -n1)"
          fi

          [ -n "$session" ] || exit 1
          printf '%s %s\n' "$session" "$(now)" > "$session_file"
          printf '%s\n' "$session"
        }

        decrypt_items() {
          session="$1"
          [ -s "$items_file" ] || return 1
          ${pkgs.gnupg}/bin/gpg --quiet -d --batch --yes --pinentry-mode loopback --passphrase "$session" "$items_file" 2>/dev/null
        }

        sync_items() {
          session="$1"
          bw config server "$server_url" >/dev/null 2>&1 || true
          bw sync --session "$session" >/dev/null 2>&1 || true
          bw list items --session "$session" \
            | ${pkgs.gnupg}/bin/gpg --symmetric --batch --yes --pinentry-mode loopback --passphrase "$session" --cipher-algo AES256 -o "$items_file"
        }

        menu() {
          prompt="$1"
          message="$2"
          ${pkgs.rofi}/bin/rofi \
            -dmenu \
            -i \
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
          json="$1"
          urls="$(${pkgs.jq}/bin/jq -r '.[] | .login.uris[]?.uri' <<< "$json" | ${pkgs.coreutils}/bin/sort -u)"
          [ -n "$urls" ] || return 1
          selected_url="$(printf '%s\n' "$urls" | ${pkgs.rofi}/bin/rofi -dmenu -i -p URL)" || return 1
          [ -n "$selected_url" ] || return 1
          printf '%s\n' "$selected_url"
        }

        choose_folder() {
          session="$1"
          folders_json="$(bw list folders --session "$session" 2>/dev/null || true)"
          choices="$(printf 'No Folder\t__ROOT__\n%s\n' "$(${pkgs.jq}/bin/jq -r '.[] | [.name // "", .id] | @tsv' <<< "$folders_json")")"
          selected_folder="$(printf '%s\n' "$choices" | ${pkgs.rofi}/bin/rofi -dmenu -i -p Folder -format i)" || return 1
          [ -n "$selected_folder" ] || return 1
          folder_id=""
          idx=0
          while IFS= read -r line; do
            if [ "$idx" -eq "$selected_folder" ]; then
              folder_id="$(printf '%s' "$line" | ${pkgs.coreutils}/bin/cut -f2)"
              break
            fi
            idx=$((idx + 1))
          done <<EOF
    $choices
    EOF
          case "$folder_id" in
            __ROOT__) folder_id="" ;;
          esac
          printf '%s\n' "$folder_id"
        }

        filter_by_url() {
          json="$1"
          url="$2"
          ${pkgs.jq}/bin/jq -c --arg url "$url" '[.[] | select(.type == 1 and any(.login.uris[]?; .uri == $url))]' <<< "$json"
        }

        filter_by_folder() {
          json="$1"
          folder_id="$2"
          ${pkgs.jq}/bin/jq -c --arg folder_id "$folder_id" '[.[] | select(.type == 1 and ((.folderId // "") == $folder_id))]' <<< "$json"
        }

        current_session="$(read_cached_session || true)"
        items_json=""

        case "''${1-}" in
          --sync)
            if [ -z "$current_session" ]; then
              current_session="$(authenticate_session)"
            fi
            sync_items "$current_session"
            exit 0
            ;;
        esac

        if [ -n "$current_session" ]; then
          items_json="$(decrypt_items "$current_session" || true)"
        fi

        if [ -z "$items_json" ]; then
          current_session="$(authenticate_session)"
          sync_items "$current_session"
          items_json="$(decrypt_items "$current_session")"
        fi

        view_json="$(${pkgs.jq}/bin/jq -c '[.[] | select(.type == 1)]' <<< "$items_json")"
        message="Alt+y sync | Alt+u urls | Alt+o folders | Alt+l lock | Alt+g totp"

        while true; do
          choices="$(${pkgs.jq}/bin/jq -r '.[] | [.name // "", (.login.username // ""), .id] | @tsv' <<< "$view_json")"
          [ -n "$choices" ] || exit 0

          code=0
          selected_index="$(printf '%s\n' "$choices" | menu "Bitwarden" "$message")" || code=$?

          selected_line=""
          idx=0
          while IFS= read -r line; do
            if [ "$idx" -eq "$selected_index" ]; then
              selected_line="$line"
              break
            fi
            idx=$((idx + 1))
          done <<EOF
    $choices
    EOF
          selected_item_id="$(printf '%s' "$selected_line" | ${pkgs.coreutils}/bin/cut -f3)"

          if [ "$code" -eq 0 ]; then
            password="$(${pkgs.jq}/bin/jq -r --arg id "$selected_item_id" '.[] | select(.id == $id) | .login.password // empty' <<< "$view_json")"
            [ -n "$password" ] || exit 0
            printf '%s' "$password" | ${pkgs.wl-clipboard}/bin/wl-copy
            exit 0
          fi

          case "$code" in
            10)
              current_session="$(authenticate_session)"
              sync_items "$current_session"
              items_json="$(decrypt_items "$current_session")"
              view_json="$(${pkgs.jq}/bin/jq -c '[.[] | select(.type == 1)]' <<< "$items_json")"
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
              bw lock >/dev/null 2>&1 || true
              rm -f "$session_file"
              exit 0
              ;;
            14)
              totp="$(${pkgs.bitwarden-cli}/bin/bw get totp "$selected_item_id" --session "$current_session" 2>/dev/null | ${pkgs.coreutils}/bin/tail -n1)"
              [ -n "$totp" ] || continue
              printf '%s' "$totp" | ${pkgs.wl-clipboard}/bin/wl-copy
              exit 0
              ;;
            *)
              exit 0
              ;;
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
