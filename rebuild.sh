#!/usr/bin/env bash
# Usage: ./rebuild.sh [flake-host [ssh-destination]]
set -euo pipefail

cd -- "$(dirname -- "${BASH_SOURCE[0]}")"
case $# in
  0)
    target=$(hostname -s)
    [[ "$target" != laptop-ara ]] || target=hp-ara
    echo "Rebuilding $target locally..."
    OLD_SYSTEM=$(readlink -f /run/current-system)
    /run/current-system/sw/bin/nixos-rebuild switch --no-reexec --flake ".#$target" --sudo
    if command -v nvd >/dev/null; then
      nvd diff "$OLD_SYSTEM" /run/current-system || true
    fi
    ;;
  1|2)
    target=$1
    case "$target" in
      tortuga) machine=tortuga; destination=${2:-nrm@192.168.1.133} ;;
      hp-ara) machine=laptop-ara; destination=${2:-nrm@laptop-ara} ;;
      *) echo "Unknown flake host: $target" >&2; exit 2 ;;
    esac

    echo "Sending $target configuration to $destination..."
    ssh_args=(-o ForwardAgent=no -o StrictHostKeyChecking=yes)
    # Send the flake source, not locally built store paths that require a trusted signature.
    snapshot=$(git ls-files --cached --deduplicate -z |
      while IFS= read -r -d '' file; do
        if [[ -e "$file" || -L "$file" ]]; then printf '%s\0' "$file"; fi
      done |
      tar -cf - --no-recursion --null --files-from=- |
      ssh -T "${ssh_args[@]}" -- "$destination" "
        set -eu
        test \"\$(hostname -s)\" = '$machine' || { echo 'Unexpected remote hostname' >&2; exit 1; }
        snapshot=\$(mktemp -d .nixos-rebuild.XXXXXXXX)
        if ! tar -xf - -C \"\$snapshot\"; then
          rm -rf -- \"\$snapshot\"
          exit 1
        fi
        printf '%s\\n' \"\$snapshot\"
      ")
    [[ "$snapshot" =~ ^\.nixos-rebuild\.[[:alnum:]]{8}$ ]] || {
      echo "Invalid remote snapshot path" >&2
      exit 1
    }

    echo "Rebuilding $target on $destination..."
    ssh -t "${ssh_args[@]}" -- "$destination" "
      set -eu
      test \"\$(hostname -s)\" = '$machine' || { echo 'Unexpected remote hostname' >&2; exit 1; }
      trap 'rm -rf -- \"\$HOME/$snapshot\"' EXIT
      sudo /run/current-system/sw/bin/nixos-rebuild switch --no-reexec --flake \"path:\$HOME/$snapshot#$target\"
    "
    ;;
  *) echo "Usage: $0 [flake-host [ssh-destination]]" >&2; exit 2 ;;
esac

echo "Configuration applied on $target."
if command -v notify-send >/dev/null; then
  notify-send "NixOS" "Configuration applied on $target" || true
fi
