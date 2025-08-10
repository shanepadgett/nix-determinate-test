{ pkgs }:

let
  common = import ./lib/common.nix;
in
pkgs.writeShellApplication {
  name = "gcp";
  runtimeInputs = with pkgs; [
    git
  ];
  text = ''
    set -euo pipefail

    ${common.colors}
    ${common.git}

    usage() {
      cat >&2 <<'USAGE'
    Usage: gcp "commit message"

    Git commit and push utility that:
    - Adds all changes (git add --all)
    - Commits with the provided message
    - Pushes to the current branch

    Examples:
      gcp "Fix bug in user authentication"
      gcp "Add new feature for data export"

    Requirements:
    - Git user.name and user.email must be configured
    - Must be run from within a git repository
    - Remote repository must be configured
    USAGE
    }

    # shellcheck disable=SC2317  # Don't warn about unreachable commands in this function
    # Main function
    main() {
      # Check arguments
      if [ $# -eq 0 ]; then
        error "Commit message required"
        usage
        exit 1
      fi

      if [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
        usage
        exit 0
      fi

      local commit_message="$1"

      # Validate we're in a git repository
      if ! git rev-parse --git-dir >/dev/null 2>&1; then
        error "Not in a git repository"
        info "Run 'git init' to initialize a repository"
        exit 1
      fi

      # Check git user configuration
      if ! check_git_user_config; then
        exit 1
      fi

      # Check if there are any changes to commit
      if git diff --quiet && git diff --cached --quiet; then
        warn "No changes to commit"
        exit 0
      fi

      # Show what will be committed
      info "Changes to be committed:"
      git status --short

      # Perform git operations
      info "Adding all changes..."
      if ! git add --all; then
        error "Failed to add changes"
        exit 1
      fi

      info "Committing with message: $commit_message"
      if ! git commit -m "$commit_message"; then
        error "Failed to commit changes"
        exit 1
      fi

      info "Pushing to remote..."
      if ! git push; then
        error "Failed to push changes"
        info "You may need to set up a remote repository or configure push settings"
        exit 1
      fi

      success "Successfully committed and pushed changes"
    }

    main "$@"
  '';
}
