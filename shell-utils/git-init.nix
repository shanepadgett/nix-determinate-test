{ pkgs }:

let
  common = import ./lib/common.nix;
in
pkgs.writeShellApplication {
  name = "git-init";
  runtimeInputs = with pkgs; [
    git
    gh
    coreutils    # mkdir, basename, dirname
    gnused       # sed for template replacement
    gnugrep      # grep for validation
  ];
  text = ''
    set -euo pipefail

    ${common.colors}
    ${common.github}
    ${common.git}
    ${common.validation}
    ${common.interaction}

    usage() {
      cat >&2 <<'USAGE'
    Usage: git-init [OPTIONS]

    Git project initialization utility that:
    - Creates a new GitHub repository
    - Initializes local git repository
    - Creates README.md and .gitignore files
    - Makes initial commit and pushes to remote

    Options:
      -h, --help         Show this help message

    Interactive prompts will guide you through:
    - Repository name and description
    - Visibility (private/public/internal)
    - Template options
    - Project location
    - GitHub features

    Requirements:
    - Git user.name and user.email must be configured
    - GitHub CLI must be installed and authenticated
    - Internet connection for GitHub operations

    Examples:
      git-init           # Start interactive repository creation
    USAGE
    }

    # shellcheck disable=SC2317  # Don't warn about unreachable commands in this function
    # Check if GitHub CLI is authenticated
    check_github_auth_with_login() {
      if ! check_github_cli; then
        return 1
      fi

      if ! gh auth status >/dev/null 2>&1; then
        warn "GitHub CLI is not authenticated"
        info "Starting GitHub authentication process..."

        if gh auth login; then
          success "GitHub CLI authentication completed"
          return 0
        else
          error "GitHub CLI authentication failed"
          return 1
        fi
      fi

      success "GitHub CLI is authenticated"
      return 0
    }

    # shellcheck disable=SC2317  # Don't warn about unreachable commands in this function
    # Create project directory and navigate to it
    setup_project_directory() {
      local project_name="$1"

      if [ ! -d "$project_name" ]; then
        info "Creating project directory: $project_name"
        mkdir -p "$project_name"
      fi

      cd "$project_name" || return 1
    }

    # shellcheck disable=SC2317  # Don't warn about unreachable commands in this function
    # Initialize git repository
    initialize_git_repo() {
      if [ ! -d ".git" ]; then
        info "Initializing git repository..."
        git init
        success "Git repository initialized"
      else
        warn "Git repository already exists"
      fi
    }

    # shellcheck disable=SC2317  # Don't warn about unreachable commands in this function
    # Create README.md file
    create_readme() {
      local project_name="$1"
      local description="$2"

      if [ ! -f "README.md" ]; then
        info "Creating README.md..."
        cat > "README.md" <<EOF
# $project_name

''${description:-"A new project"}

## Description

TODO: Add project description

## Installation

TODO: Add installation instructions

## Usage

TODO: Add usage instructions

## Contributing

TODO: Add contributing guidelines

## License

TODO: Add license information
EOF
        success "README.md created"
      fi
    }

    # shellcheck disable=SC2317  # Don't warn about unreachable commands in this function
    # Create .gitignore file
    create_gitignore() {
      if [ ! -f ".gitignore" ]; then
        info "Creating .gitignore..."
        cat > ".gitignore" <<'EOF'
# OS generated files
.DS_Store
.DS_Store?
._*
.Spotlight-V100
.Trashes
ehthumbs.db
Thumbs.db

# Editor files
*.swp
*.swo
*~
.vscode/
.idea/

# Logs
*.log
logs/

# Runtime data
pids/
*.pid
*.seed

# Dependency directories
node_modules/
vendor/

# Build outputs
dist/
build/
target/
*.o
*.so
*.dylib

# Environment files
.env
.env.local
.env.*.local

# Temporary files
tmp/
temp/
EOF
        success ".gitignore created"
      fi
    }

    # shellcheck disable=SC2317  # Don't warn about unreachable commands in this function
    # Create initial commit and push
    create_initial_commit() {
      info "Creating initial commit and pushing to remote..."

      # Add all files
      git add --all

      # Create commit
      if git commit -m "feat: initial project setup

- Add README.md with project structure
- Add comprehensive .gitignore
- Set up basic project foundation"; then
        info "Initial commit created"
      else
        error "Failed to create initial commit"
        return 1
      fi

      # Push to remote
      if git push -u origin main; then
        success "Initial commit pushed to remote"
      else
        error "Failed to push to remote"
        return 1
      fi
    }

    # shellcheck disable=SC2317  # Don't warn about unreachable commands in this function
    # Interactive prompt for repository details
    prompt_for_repo_details() {
      # Repository name
      while true; do
        echo
        printf "Repository name: "
        read -r repo_name || true
        if [ -n "$repo_name" ]; then
          if validate_repo_name "$repo_name"; then
            break
          fi
        else
          error "Repository name is required"
        fi
      done

      # Description
      echo
      printf "Description (optional): "
      read -r repo_description || true

      # Visibility
      echo
      info "Repository visibility:"
      echo "  1) Private (only you and collaborators) [default]"
      echo "  2) Public (anyone can see)"
      echo "  3) Internal (organization members only)"
      local visibility_choice
      while true; do
        printf "Choose visibility [1-3] (default: 1): "
        read -r visibility_choice || true
        # Use default if empty
        visibility_choice=''${visibility_choice:-1}
        case "$visibility_choice" in
          1) repo_visibility="private"; break ;;
          2) repo_visibility="public"; break ;;
          3) repo_visibility="internal"; break ;;
          *) error "Please choose 1, 2, or 3" ;;
        esac
      done

      # Template options
      echo
      info "Template options:"
      echo "  1) Create standard repository [default]"
      echo "  2) Create from existing template repository"
      echo "  3) Create repository to be used as template"
      local template_choice
      while true; do
        printf "Choose template option [1-3] (default: 1): "
        read -r template_choice || true
        # Use default if empty
        template_choice=''${template_choice:-1}
        case "$template_choice" in
          1) template_mode="none"; break ;;
          2)
            template_mode="from"
            printf "Template repository (owner/repo): "
            read -r template_repo || true
            break
            ;;
          3) template_mode="as"; break ;;
          *) error "Please choose 1, 2, or 3" ;;
        esac
      done

      # Location
      echo
      info "Project location:"
      echo "  1) Create in new subdirectory ./$repo_name [default]"
      echo "  2) Create in current directory"
      local location_choice
      while true; do
        printf "Choose location [1-2] (default: 1): "
        read -r location_choice || true
        # Use default if empty
        location_choice=''${location_choice:-1}
        case "$location_choice" in
          1) repo_location="subdirectory"; break ;;
          2) repo_location="current"; break ;;
          *) error "Please choose 1 or 2" ;;
        esac
      done

      # Gitignore template (only if not using a template)
      if [ "$template_mode" != "from" ]; then
        echo
        printf "Gitignore template (e.g., Node, Python, Go) [blank for general]: "
        read -r gitignore_template || true
      fi
    }

    # Parse command line arguments
    while [ "$#" -gt 0 ]; do
      case "$1" in
        -h|--help) usage; exit 0 ;;
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

    # Check prerequisites
    if ! check_git_user_config || ! check_github_auth_with_login; then
      exit 1
    fi

    header "GitHub Repository Creation Wizard"

    # Get repository details from user
    prompt_for_repo_details

    echo
    header "Creating Repository: $repo_name"

    # Build gh repo create command
    gh_command="gh repo create $repo_name"
    gh_command="$gh_command --$repo_visibility"

    if [ -n "$repo_description" ]; then
      gh_command="$gh_command --description \"$repo_description\""
    fi

    # Handle template creation (FROM template)
    if [ "$template_mode" = "from" ] && [ -n "$template_repo" ]; then
      gh_command="$gh_command --template $template_repo"
    fi

    # Add GitHub-managed files only if not using a template
    if [ "$template_mode" != "from" ]; then
      if [ -n "$gitignore_template" ]; then
        gh_command="$gh_command --gitignore $gitignore_template"
      fi
    fi

    gh_command="$gh_command --clone"

    # Execute repository creation
    info "Running: $gh_command"
    if eval "$gh_command"; then
      success "GitHub repository created successfully"
    else
      error "Failed to create GitHub repository"
      exit 1
    fi

    # Navigate to the repository directory
    if [ "$repo_location" = "subdirectory" ]; then
      cd "$repo_name" || {
        error "Failed to navigate to cloned repository"
        exit 1
      }
    fi

    # If not using a template, create local files
    if [ "$template_mode" != "from" ]; then
      # Always create README from local template
      create_readme "$repo_name" "$repo_description"

      # Only create gitignore if not already created by GitHub
      if [ -z "$gitignore_template" ]; then
        create_gitignore
      fi

      # Always create initial commit since we always add local files
      create_initial_commit
    fi

    # Handle template repository setup
    if [ "$template_mode" = "as" ]; then
      echo
      warn "Repository will be marked as template..."
      warn "GitHub CLI doesn't support marking repositories as templates during creation"
      info "You'll need to manually enable this in GitHub settings after creation"
      echo "  1. Visit: https://github.com/$(get_github_user)/$repo_name/settings"
      echo "  2. Check 'Template repository' option"
    fi

    # Show completion message
    echo
    success "Repository setup complete!"
    info "Project initialized in: $(pwd)"
    info "GitHub repository: https://github.com/$(get_github_user)/$repo_name"
    echo
    info "Next steps:"
    if [ "$template_mode" = "as" ]; then
      echo "  1. Mark repository as template (see instructions above)"
      echo "  2. Make changes and commit: git add . && git commit -m 'your message'"
      echo "  3. Push changes: git push"
      echo "  4. Create pull requests using: gh pr create"
    else
      echo "  1. Make changes and commit: git add . && git commit -m 'your message'"
      echo "  2. Push changes: git push"
      echo "  3. Create pull requests using: gh pr create"
    fi
  '';
}
