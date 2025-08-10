#!/bin/zsh
# Repository deletion shell function
# Deletes a repository both on GitHub and locally with safety checks
# This function runs in the current shell and can change the working directory

# Repository deletion function
delete-repo() {
  # Source common utilities from the actual installation directory
  if [[ -f "$HOME/.dotfiles/scripts/dev-commands/common.sh" ]]; then
    # shellcheck disable=SC1091
    source "$HOME/.dotfiles/scripts/dev-commands/common.sh"
  else
    echo "Error: Could not load common utilities"
    return 1
  fi

  # Configuration
  local repo_name=""
  local delete_local=true
  local delete_remote=true
  local force_delete=false

  # Show usage information
  show_usage() {
    echo "Usage: delete-repo [REPOSITORY_NAME|.] [OPTIONS]"
    echo
    echo "Delete a repository both on GitHub and locally"
    echo
    echo "Arguments:"
    echo "  REPOSITORY_NAME    Name of the repository to delete"
    echo "  .                  Delete the current repository (if in a git repo)"
    echo "  (none)             Auto-detect current repo or prompt for name"
    echo
    echo "Options:"
    echo "  -f, --force        Skip confirmation prompts"
    echo "  -l, --local-only   Delete only the local repository"
    echo "  -r, --remote-only  Delete only the GitHub repository"
    echo "  -h, --help         Show this help message"
    echo
    echo "Examples:"
    echo "  delete-repo                # Delete current repository (if in git repo)"
    echo "  delete-repo .              # Delete current repository (explicit)"
    echo "  delete-repo my-project     # Delete specified repository"
    echo "  delete-repo -l my-project  # Delete only local repository"
    echo "  delete-repo -r my-project  # Delete only GitHub repository"
    echo "  delete-repo -f my-project  # Delete without confirmation prompts"
  }

  # Check if GitHub CLI is authenticated
  check_github_auth() {
    if ! check_github_cli; then
      return 1
    fi

    if ! gh auth status &>/dev/null; then
      print_error "GitHub CLI is not authenticated"
      print_info "Run 'gh auth login' to authenticate"
      return 1
    fi

    return 0
  }

  # Get repository information from GitHub
  get_repo_info() {
    local repo_name="$1"
    local github_user

    github_user=$(gh api user --jq '.login' 2>/dev/null || true)

    if [[ -z $github_user ]]; then
      print_error "Could not determine GitHub username"
      return 1
    fi

    local repo_full_name="${github_user}/${repo_name}"

    # Check if repository exists on GitHub
    if gh repo view "$repo_full_name" &>/dev/null; then
      echo "$repo_full_name"
      return 0
    else
      return 1
    fi
  }

  # Delete GitHub repository
  delete_github_repo() {
    local repo_full_name="$1"
    local force_delete="$2"

    print_info "Deleting GitHub repository: $repo_full_name"

    if [[ $force_delete != "true" ]]; then
      echo
      print_warning "This will permanently delete the GitHub repository: $repo_full_name"
      print_warning "This action cannot be undone!"
      echo
      local confirm
      read -r "confirm?Are you sure you want to delete this GitHub repository? [y/N]: "

      if [[ ${confirm:l} != "y" ]]; then
        print_info "GitHub repository deletion cancelled"
        return 1
      fi
    fi

    # Check if we have the delete_repo scope and request it if needed
    if ! gh auth status --show-token 2>/dev/null | grep -q "delete_repo"; then
      print_info "Requesting delete_repo scope for GitHub CLI..."
      if ! gh auth refresh -h github.com -s delete_repo; then
        print_error "Failed to refresh GitHub authentication with delete_repo scope"
        print_info "Please run: gh auth refresh -h github.com -s delete_repo"
        return 1
      fi
      print_success "GitHub authentication refreshed with delete_repo scope"
    fi

    if gh repo delete "$repo_full_name" --yes; then
      print_success "GitHub repository deleted successfully"
      return 0
    else
      print_error "Failed to delete GitHub repository"
      return 1
    fi
  }

  # Delete local repository
  delete_local_repo() {
    local repo_path="$1"
    local force_delete="$2"

    print_info "Deleting local repository: $repo_path"

    if [[ $force_delete != "true" ]]; then
      echo
      print_warning "This will permanently delete the local directory: $repo_path"
      print_warning "All local changes will be lost!"
      echo
      local confirm
      read -r "confirm?Are you sure you want to delete this local repository? [y/N]: "

      if [[ ${confirm:l} != "y" ]]; then
        print_info "Local repository deletion cancelled"
        return 1
      fi
    fi

    # Safety check: ensure we're not deleting important directories
    local abs_path
    abs_path=$(realpath "$repo_path" 2>/dev/null || echo "$repo_path")

    # Prevent deletion of home directory, root, or dotfiles
    case "$abs_path" in
      "$HOME" | "/" | "$HOME/.dotfiles" | "$HOME/.")
        print_error "Refusing to delete system directory: $abs_path"
        return 1
        ;;
    esac

    if rm -rf "$repo_path"; then
      print_success "Local repository deleted successfully"
      return 0
    else
      print_error "Failed to delete local repository"
      return 1
    fi
  }

  # Check if we're currently in a git repository and get repo name
  get_current_repo_name() {
    # Check if we're in a git repository
    if ! git rev-parse --git-dir >/dev/null 2>&1; then
      return 1
    fi

    # Get the repository name from the git root directory
    local repo_root
    local repo_name
    repo_root=$(git rev-parse --show-toplevel 2>/dev/null)

    if [[ -n $repo_root ]]; then
      repo_name=$(basename "$repo_root")
      echo "$repo_name"
      return 0
    else
      return 1
    fi
  }

  # Prompt for repository name if not provided
  prompt_for_repo_name() {
    local repo_name
    while true; do
      echo
      read -r "repo_name?Repository name to delete: "
      if [[ -n $repo_name ]]; then
        # Validate repository name (basic GitHub rules)
        if [[ $repo_name =~ ^[a-zA-Z0-9._-]+$ ]]; then
          echo "$repo_name"
          return 0
        else
          print_error "Repository name can only contain alphanumeric characters, dots, dashes, and underscores"
        fi
      else
        print_error "Repository name is required"
      fi
    done
  }

  # Main deletion logic
  delete_repository() {
    local repo_name="$1"
    local delete_local="$2"
    local delete_remote="$3"
    local force_delete="$4"

    local repo_full_name=""
    local local_repo_path="./$repo_name"
    local local_exists=false
    local remote_exists=false
    local deletion_success=true
    local need_to_move_up=false
    local repo_parent=""

    # Check if we're currently inside the repository (anywhere within it)
    if git rev-parse --git-dir >/dev/null 2>&1; then
      local repo_root
      repo_root=$(git rev-parse --show-toplevel 2>/dev/null)
      if [[ -n $repo_root ]]; then
        local actual_repo_name
        actual_repo_name=$(basename "$repo_root")
        if [[ $actual_repo_name == "$repo_name" ]]; then
          local_repo_path="."
          need_to_move_up=true
          repo_parent=$(dirname "$repo_root")
          print_info "Currently inside the repository (detected repo: $actual_repo_name)"
        else
          print_warning "Inside git repository '$actual_repo_name' but looking for '$repo_name'"
        fi
      fi
    fi

    # Check remote repository existence
    if [[ $delete_remote == "true" ]]; then
      if ! check_github_auth; then
        print_error "Cannot delete remote repository without GitHub authentication"
        return 1
      fi

      if repo_full_name=$(get_repo_info "$repo_name"); then
        remote_exists=true
        print_info "Found GitHub repository: $repo_full_name"
      else
        print_warning "GitHub repository '$repo_name' not found or not accessible"
      fi
    fi

    # Check local repository existence
    if [[ $delete_local == "true" ]]; then
      # If we're inside the repository (local_repo_path="." was set), we know it exists
      if [[ $local_repo_path == "." ]]; then
        local_exists=true
        print_info "Local repository confirmed (currently inside it)"
      elif [[ -d $local_repo_path && -d "$local_repo_path/.git" ]]; then
        local_exists=true
        print_info "Found local repository: $local_repo_path"
      else
        print_warning "Local repository '$local_repo_path' not found"
      fi
    fi

    # Verify that at least one repository exists
    if [[ $local_exists == false && $remote_exists == false ]]; then
      print_error "No repositories found to delete"
      return 1
    fi

    echo
    print_header "Repository Deletion Summary"
    print_info "Repository: $repo_name"
    [[ $remote_exists == true ]] && print_info "GitHub: $repo_full_name (will be deleted)"
    [[ $local_exists == true ]] && print_info "Local: $local_repo_path (will be deleted)"

    # Delete remote repository first
    if [[ $delete_remote == "true" && $remote_exists == true ]]; then
      if ! delete_github_repo "$repo_full_name" "$force_delete"; then
        deletion_success=false
      fi
    fi

    # Delete local repository
    if [[ $delete_local == "true" && $local_exists == true ]]; then
      print_info "Starting local repository deletion process..."

      # If we're inside the repository, navigate to parent first
      if [[ $need_to_move_up == true ]]; then
        # Get the target directory name before changing directories
        local target_dir
        target_dir=$(basename "$(git rev-parse --show-toplevel 2>/dev/null)" 2>/dev/null || echo "$repo_name")

        print_info "Moving to parent directory before deletion: $repo_parent"

        if cd "$repo_parent"; then
          print_info "Successfully moved to: $(pwd)"
          print_info "Will delete repository directory: $target_dir"

          if ! delete_local_repo "$target_dir" "$force_delete"; then
            print_error "Local repository deletion failed"
            deletion_success=false
          fi
        else
          print_error "Failed to change to parent directory: $repo_parent"
          deletion_success=false
        fi
      else
        # We're not inside the repo, use the original path
        if ! delete_local_repo "$local_repo_path" "$force_delete"; then
          print_error "Local repository deletion failed"
          deletion_success=false
        fi
      fi
    fi

    if [[ $deletion_success == true ]]; then
      echo
      print_success "Repository deletion completed successfully"

      # If we moved up, we're already in the right place
      if [[ $need_to_move_up == true ]]; then
        print_info "Current directory: $(pwd)"
      fi

      return 0
    else
      echo
      print_error "Some deletions failed. Check the output above for details."
      return 1
    fi
  }

  # Parse command line arguments
  while [[ $# -gt 0 ]]; do
    case $1 in
      -h | --help)
        show_usage
        return 0
        ;;
      -f | --force)
        force_delete=true
        shift
        ;;
      -l | --local-only)
        delete_local=true
        delete_remote=false
        shift
        ;;
      -r | --remote-only)
        delete_local=false
        delete_remote=true
        shift
        ;;
      -*)
        print_error "Unknown option: $1"
        show_usage
        return 1
        ;;
      *)
        if [[ -z $repo_name ]]; then
          repo_name="$1"
        else
          print_error "Multiple repository names provided: $repo_name, $1"
          show_usage
          return 1
        fi
        shift
        ;;
    esac
  done

  # Handle repository name resolution
  if [[ -z $repo_name ]] || [[ $repo_name == "." ]]; then
    # Try to get current repository name
    if repo_name=$(get_current_repo_name); then
      print_info "Using current repository: $repo_name"
    else
      if [[ $repo_name == "." ]]; then
        print_error "Current directory is not a git repository"
        print_info "Use 'delete-repo <name>' to specify a repository name"
        return 1
      else
        # Prompt for repository name if not in a git repo and none provided
        repo_name=$(prompt_for_repo_name)
      fi
    fi
  fi

  print_header "Repository Deletion Tool"

  # Execute deletion
  delete_repository "$repo_name" "$delete_local" "$delete_remote" "$force_delete"
}
