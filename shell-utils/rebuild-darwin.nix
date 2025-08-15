{ pkgs }:

let
  common = import ./lib/common.nix;
in
pkgs.writeShellApplication {
  name = "rebuild-darwin";
  runtimeInputs = with pkgs; [ coreutils ];
  text = ''
    set -euo pipefail

    ${common.colors}
    ${common.interaction}

    usage() {
      cat >&2 <<'USAGE'
Usage: rebuild-darwin

Rebuild and apply the Nix-darwin configuration using the dotfiles repository.

This runs:
  sudo darwin-rebuild switch --flake ~/.dotfiles#default

USAGE
    }

    # Parse arguments
    while [ "$#" -gt 0 ]; do
      case "$1" in
        -h|--help)
          usage
          exit 0
          ;;
        *)
          usage
          exit 1
          ;;
      esac
    done

    # Execute the rebuild
    sudo darwin-rebuild switch --flake ~/.dotfiles#default
  '';
}
