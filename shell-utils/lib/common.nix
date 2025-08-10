# Common utility functions for shell scripts
# This provides shared functionality across all shell utilities

{
  # Color and formatting functions
  # These replace the need to source external common.sh files
  colors = ''
    # shellcheck disable=SC2317  # Don't warn about unreachable commands in these functions
    # Color output functions
    info()    { printf "\033[36mℹ %s\033[0m\n" "$*"; }
    warn()    { printf "\033[33m⚠ %s\033[0m\n" "$*"; }
    error()   { printf "\033[31m✖ %s\033[0m\n" "$*" >&2; }
    success() { printf "\033[32m✔ %s\033[0m\n" "$*"; }
    header()  { printf "\n\033[1m== %s ==\033[0m\n" "$*"; }

    # Legacy aliases for compatibility
    # shellcheck disable=SC2317  # Don't warn about unreachable commands in this function
    print_info() { info "$@"; }
    # shellcheck disable=SC2317  # Don't warn about unreachable commands in this function
    print_warn() { warn "$@"; }
    # shellcheck disable=SC2317  # Don't warn about unreachable commands in this function
    print_error() { error "$@"; }
    # shellcheck disable=SC2317  # Don't warn about unreachable commands in this function
    print_success() { success "$@"; }
    # shellcheck disable=SC2317  # Don't warn about unreachable commands in this function
    print_header() { header "$@"; }
  '';

  # GitHub CLI helper functions
  github = ''
    # shellcheck disable=SC2317  # Don't warn about unreachable commands in this function
    # Check if GitHub CLI is available and authenticated
    check_github_cli() {
      if ! command -v gh >/dev/null 2>&1; then
        error "GitHub CLI (gh) is required but not found"
        info "Install with: nix-shell -p gh"
        return 1
      fi
    }

    # shellcheck disable=SC2317  # Don't warn about unreachable commands in this function
    check_github_auth() {
      check_github_cli || return 1
      if ! gh auth status >/dev/null 2>&1; then
        error "GitHub CLI is not authenticated"
        info "Run: gh auth login"
        return 1
      fi
    }

    # shellcheck disable=SC2317  # Don't warn about unreachable commands in this function
    get_github_user() {
      gh api user --jq '.login' 2>/dev/null || true
    }
  '';

  # Git helper functions
  git = ''
    # shellcheck disable=SC2317  # Don't warn about unreachable commands in this function
    # Check if git user configuration is set
    check_git_user_config() {
      local git_name git_email
      git_name="$(git config user.name 2>/dev/null || true)"
      git_email="$(git config user.email 2>/dev/null || true)"

      if [ -z "$git_name" ] || [ -z "$git_email" ]; then
        error "Git user configuration is not set"
        info "Please configure your git user name and email:"
        info '  git config --global user.name "Your Name"'
        info '  git config --global user.email "your.email@example.com"'
        return 1
      fi
      return 0
    }

    # shellcheck disable=SC2317  # Don't warn about unreachable commands in this function
    # Get current repository name
    get_current_repo_name() {
      if ! git rev-parse --git-dir >/dev/null 2>&1; then
        return 1
      fi
      local root
      root="$(git rev-parse --show-toplevel 2>/dev/null || true)"
      [ -z "$root" ] && return 1
      basename "$root"
    }
  '';

  # Validation functions
  validation = ''
    # shellcheck disable=SC2317  # Don't warn about unreachable commands in this function
    # Validate repository name (GitHub rules)
    validate_repo_name() {
      local name="$1"
      if [ -z "$name" ]; then
        error "Repository name is required"
        return 1
      fi

      # Check for invalid characters
      if echo "$name" | grep -q '[^a-zA-Z0-9._-]'; then
        error "Repository name can only contain alphanumeric characters, dots, dashes, and underscores"
        return 1
      fi

      return 0
    }

    # shellcheck disable=SC2317  # Don't warn about unreachable commands in this function
    # Safety check for directory deletion
    validate_safe_path() {
      local path="$1"
      local abs_path
      abs_path="$(realpath "$path" 2>/dev/null || echo "$path")"

      case "$abs_path" in
        "$HOME" | "/" | "$HOME/.dotfiles" | "$HOME/."*)
          error "Refusing to delete system directory: $abs_path"
          return 1
          ;;
        *)
          return 0
          ;;
      esac
    }
  '';

  # User interaction functions
  interaction = ''
    # shellcheck disable=SC2317  # Don't warn about unreachable commands in this function
    # Prompt for confirmation
    confirm() {
      local message="$1"
      local default="''${2:-N}"
      local prompt

      case "$default" in
        [Yy]*) prompt="[Y/n]" ;;
        *) prompt="[y/N]" ;;
      esac

      printf "%s %s: " "$message" "$prompt"
      read -r response || true

      case "$response" in
        [Yy]*) return 0 ;;
        [Nn]*) return 1 ;;
        "")
          case "$default" in
            [Yy]*) return 0 ;;
            *) return 1 ;;
          esac
          ;;
        *) return 1 ;;
      esac
    }

    # shellcheck disable=SC2317  # Don't warn about unreachable commands in this function
    # Prompt for input with validation
    prompt_input() {
      local prompt="$1"
      local validator="$2"  # Optional validation function
      local value

      while true; do
        printf "%s: " "$prompt"
        read -r value || true

        if [ -n "$value" ]; then
          if [ -z "$validator" ] || "$validator" "$value"; then
            printf "%s" "$value"
            return 0
          fi
        else
          error "Input is required"
        fi
      done
    }
  '';
}
