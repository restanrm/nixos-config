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

# Exécution du rebuild avec sudo
# --flake .#hp-ara utilise le répertoire courant et le nom d'hôte spécifié
sudo nixos-rebuild switch --flake .#$HOSTNAME

# Récupération du résultat
if [ $? -eq 0 ]; then
  echo "󰄬 Configuration appliquée avec succès !"

  # Affichage du diff entre les générations
  if command -v nvd &>/dev/null; then
    echo "󰒡 Changements depuis la dernière génération :"
    nvd diff /run/current-system "$CONF_DIR/result"
  fi
else
  echo "󰅙 Erreur lors de la reconstruction."
fi

# Nettoyage du lien symbolique temporaire 'result'
[ -L result ] && rm result

popd >/dev/null
