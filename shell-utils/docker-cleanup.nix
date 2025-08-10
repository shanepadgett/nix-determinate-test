{ pkgs }:

let
  common = import ./lib/common.nix;
in
pkgs.writeShellApplication {
  name = "docker-cleanup";
  runtimeInputs = with pkgs; [
    docker-client
    coreutils
    gnugrep
  ];
  text = ''
    set -euo pipefail

    ${common.colors}
    ${common.interaction}

    usage() {
      cat >&2 <<'USAGE'
    Usage: docker-cleanup [OPTIONS]

    Clean up Docker containers, images, volumes, and networks.

    Options:
      -f, --force        Skip confirmation prompts
      -h, --help         Show this help message

    WARNING: This will remove ALL Docker containers, images, volumes, and networks!
    This includes any persistent data stored in volumes.

    Examples:
      docker-cleanup           # Interactive cleanup with confirmation
      docker-cleanup -f        # Force cleanup without confirmation
    USAGE
    }

    # shellcheck disable=SC2317  # Don't warn about unreachable commands in this function
    run_cleanup() {
      local description="$1"
      local list_command="$2"
      local cleanup_command="$3"

      info "$description..."

      local items
      items=$(eval "$list_command" 2>/dev/null || true)

      if [ -n "$items" ]; then
        eval "$cleanup_command" && success "$description completed"
      else
        info "No items found for: $description"
      fi
      echo ""
    }

    # shellcheck disable=SC2317  # Don't warn about unreachable commands in this function
    check_docker() {
      if ! command -v docker >/dev/null 2>&1; then
        error "Docker is not installed"
        info "Install Docker and try again"
        exit 1
      fi

      if ! docker info >/dev/null 2>&1; then
        error "Docker is not running or not accessible"
        info "Please start Docker (OrbStack/Docker Desktop) and try again"
        exit 1
      fi
    }

    # Parse arguments
    force=false
    while [ $# -gt 0 ]; do
      case "$1" in
        -h|--help)
          usage
          exit 0
          ;;
        -f|--force)
          force=true
          shift
          ;;
        -*)
          error "Unknown option: $1"
          usage
          exit 1
          ;;
        *)
          error "Unexpected argument: $1"
          usage
          exit 1
          ;;
      esac
    done

    # Check Docker availability
    check_docker

    header "Docker Cleanup Tool"
    warn "WARNING: This will remove ALL Docker containers, images, volumes, and networks!"
    warn "This includes any persistent data stored in volumes!"
    echo

    # Confirmation
    if [ "$force" != "true" ]; then
      if ! confirm "Are you sure you want to continue?"; then
        info "Docker cleanup cancelled"
        exit 0
      fi
    fi

    info "Proceeding with Docker cleanup..."
    echo

    # Stop all running containers
    run_cleanup "Stopping all running containers" \
      "docker ps -q" \
      "docker stop \$(docker ps -q)"

    # Remove all containers (including stopped ones)
    run_cleanup "Removing all containers" \
      "docker ps -aq" \
      "docker rm \$(docker ps -aq)"

    # Remove all images
    run_cleanup "Removing all images" \
      "docker images -q" \
      "docker rmi \$(docker images -q)"

    # Remove all volumes (this will delete any persistent data)
    run_cleanup "Removing all volumes" \
      "docker volume ls -q" \
      "docker volume rm \$(docker volume ls -q)"

    # Remove all custom networks (except default ones)
    run_cleanup "Removing all custom networks" \
      "docker network ls -q --filter type=custom" \
      "docker network rm \$(docker network ls -q --filter type=custom)"

    info "Cleaning up build cache and unused resources..."
    docker system prune -a --volumes -f
    success "System cleanup completed"
    echo

    success "Docker cleanup completed successfully!"
    info "Your Docker environment is now clean."
  '';
}
