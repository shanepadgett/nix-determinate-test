{ pkgs }:

let
  common = import ./lib/common.nix;
in
pkgs.writeShellApplication {
  name = "node-env";
  runtimeInputs = with pkgs; [
    coreutils
  ];
  text = ''
    set -euo pipefail

    ${common.colors}

    usage() {
      cat >&2 <<'USAGE'
    Usage: node-env [environment]

    Manage NODE_ENV environment variable for Node.js development.

    Arguments:
      environment    Set NODE_ENV to this value (development|production|test)
      (none)         Show current NODE_ENV value

    Examples:
      node-env                    # Show current NODE_ENV
      node-env development        # Set NODE_ENV=development
      node-env production         # Set NODE_ENV=production
      node-env test              # Set NODE_ENV=test

    Note: This sets NODE_ENV for the current shell session only.
    For running commands with a specific NODE_ENV, use with-node-env.
    USAGE
    }

    # Validate environment value
    validate_env() {
      local env="$1"
      case "$env" in
        development|production|test)
          return 0
          ;;
        *)
          error "Invalid environment: $env"
          info "Valid environments: development, production, test"
          return 1
          ;;
      esac
    }

    # Main function
    main() {
      case $# in
        0)
          # Show current NODE_ENV
          if [ -n "''${NODE_ENV:-}" ]; then
            info "Current NODE_ENV: $NODE_ENV"
          else
            info "NODE_ENV is not set"
          fi
          ;;
        1)
          case "$1" in
            -h|--help)
              usage
              exit 0
              ;;
            *)
              local env="$1"
              if validate_env "$env"; then
                export NODE_ENV="$env"
                success "NODE_ENV set to: $NODE_ENV"
              else
                exit 1
              fi
              ;;
          esac
          ;;
        *)
          error "Too many arguments"
          usage
          exit 1
          ;;
      esac
    }

    main "$@"
  '';
}
