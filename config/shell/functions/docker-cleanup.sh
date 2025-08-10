#!/bin/zsh
# Docker cleanup shell function
# Performs complete Docker cleanup, removing all containers, images, volumes, and networks
# WARNING: This will delete ALL Docker data including persistent volumes

# Docker cleanup function
docker-cleanup() {
  # Function to run command and handle empty results
  run_cleanup() {
    local description="$1"
    local list_command="$2"
    local cleanup_command="$3"

    echo "📋 $description..."

    # Check if there are any items to clean up
    local items
    items=$(eval "$list_command" 2>/dev/null || true)

    if [ -n "$items" ]; then
      eval "$cleanup_command" && echo "✅ $description completed"
    else
      echo "ℹ️  No items found for: $description"
    fi
    echo ""
  }

  # Check if Docker is running
  if ! docker info >/dev/null 2>&1; then
    echo "❌ Docker is not running or not accessible"
    echo "💡 Please start Docker and try again"
    return 1
  fi

  echo "🧹 Starting Docker cleanup for testing..."
  echo "⚠️  WARNING: This will remove ALL Docker containers, images, volumes, and networks!"
  echo ""

  # Prompt for confirmation
  echo -n "Are you sure you want to continue? [y/N]: "
  read -r confirmation
  case "$confirmation" in
    [yY] | [yY][eE][sS])
      echo "Proceeding with Docker cleanup..."
      echo ""
      ;;
    *)
      echo "Docker cleanup cancelled"
      return 0
      ;;
  esac

  # Stop all running containers
  # shellcheck disable=SC2016
  run_cleanup "Stopping all running containers" "docker ps -q" 'docker stop $(docker ps -q)'

  # Remove all containers (including stopped ones)
  # shellcheck disable=SC2016
  run_cleanup "Removing all containers" "docker ps -aq" 'docker rm $(docker ps -aq)'

  # Remove all images
  # shellcheck disable=SC2016
  run_cleanup "Removing all images" "docker images -q" 'docker rmi $(docker images -q)'

  # Remove all volumes (this will delete any persistent data)
  # shellcheck disable=SC2016
  run_cleanup "Removing all volumes" "docker volume ls -q" 'docker volume rm $(docker volume ls -q)'

  # Remove all custom networks (except default ones)
  # shellcheck disable=SC2016
  run_cleanup "Removing all custom networks" "docker network ls -q --filter type=custom" 'docker network rm $(docker network ls -q --filter type=custom)'

  # Clean up build cache and unused resources
  echo "📋 Cleaning up build cache and unused resources..."
  docker system prune -a --volumes -f
  echo "✅ System cleanup completed"
  echo ""

  echo "🎉 Docker cleanup completed successfully!"
  echo "💡 Your Docker environment is now clean and ready for testing."
}
