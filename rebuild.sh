#!/usr/bin/env bash
# Script de reconstruction NixOS sécurisé

set -e # Arrête le script en cas d'erreur

# Chemin de la configuration
CONF_DIR="$HOME/nixos"
HOSTNAME="hp-ara"

# Se déplacer dans le répertoire de config
pushd "$CONF_DIR" >/dev/null

echo "󱄅 Vérification de la configuration..."

# Optionnel: Formatage automatique si l'outil est présent
if command -v nixpkgs-fmt &>/dev/null; then
  nixpkgs-fmt . &>/dev/null
fi

# Git: On ajoute les nouveaux fichiers au staging pour que Nix les voit (obligatoire pour les flakes)
alejandra .
git add .

echo "󱄅 Reconstruction de NixOS ($HOSTNAME)..."
OLD_SYSTEM=$(readlink -f /run/current-system)

# Exécution du rebuild avec sudo
# --flake .#hp-ara utilise le répertoire courant et le nom d'hôte spécifié
# Si un argument est fourni, il sera utilisé comme label dans le chargeur d'amorçage
[ -n "$1" ] && export NIXOS_LABEL="$@"
# Garder le client installé, compatible avec le systemd encore en cours.
/run/current-system/sw/bin/nixos-rebuild switch --no-reexec --flake .#$HOSTNAME --sudo

# Récupération du résultat
if [ $? -eq 0 ]; then
  notify-send "󰄬 Configuration appliquée avec succès !"

  # Affichage du diff entre les générations
  if command -v nvd &>/dev/null; then
    echo "󰒡 Changements depuis la dernière génération :"
    nvd diff "$OLD_SYSTEM" /run/current-system
  fi
else
  echo "󰅙 Erreur lors de la reconstruction."
fi

popd >/dev/null
