{ pkgs }:

let
  common = import ./lib/common.nix;
in
pkgs.writeShellApplication {
  name = "with-node-env";
  runtimeInputs = with pkgs; [
    coreutils
  ];
  text = ''
    set -euo pipefail

    ${common.colors}

    usage() {
      cat >&2 <<'USAGE'
    Usage: with-node-env <environment> <command> [args...]

    Run a command with a specific NODE_ENV value.

    Arguments:
      environment    NODE_ENV value (development|production|test)
      command        Command to run
      args           Arguments to pass to the command

    Examples:
      with-node-env development npm start
      with-node-env production node server.js
      with-node-env test npm test
      with-node-env development yarn build

    This is useful for running commands with a specific NODE_ENV
    without affecting the current shell environment.
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
      if [ $# -lt 2 ]; then
        error "Missing required arguments"
        usage
        exit 1
      fi

      if [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
        usage
        exit 0
      fi

      local env="$1"
      shift

      # Validate environment
      if ! validate_env "$env"; then
        exit 1
      fi

      # Show what we're doing
      info "Running with NODE_ENV=$env: $*"

      # Execute command with NODE_ENV set
      NODE_ENV="$env" exec "$@"
    }

    main "$@"
  '';
}
