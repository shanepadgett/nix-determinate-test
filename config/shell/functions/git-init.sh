#!/bin/zsh
# Git project initialization shell function
# Creates a new project with git repo, README, .gitignore, and initial commit
# This function runs in the current shell and can change the working directory

# Git project initialization function
git-init() {
  # Source common utilities from the actual installation directory
  if [[ -f "$HOME/.dotfiles/scripts/dev-commands/common.sh" ]]; then
    # shellcheck disable=SC1091
    source "$HOME/.dotfiles/scripts/dev-commands/common.sh"
  else
    echo "Error: Could not load common utilities"
    return 1
  fi

  # Source configuration for installation paths
  if [[ -f "$HOME/.dotfiles/config/config.env" ]]; then
    # shellcheck disable=SC1091
    source "$HOME/.dotfiles/config/config.env"
  else
    echo "Error: Could not load configuration"
    return 1
  fi

  # Source git functions for gcp alias
  if [[ -f "$HOME/.dotfiles/config/shell/functions/git.sh" ]]; then
    # shellcheck disable=SC1091
    source "$HOME/.dotfiles/config/shell/functions/git.sh"
  else
    echo "Error: Could not load git functions"
    return 1
  fi

  # Check if git user configuration is set
  check_git_user_config() {
    local git_name
    local git_email
    git_name=$(git config user.name 2>/dev/null)
    git_email=$(git config user.email 2>/dev/null)

    if [ -z "$git_name" ] || [ -z "$git_email" ]; then
      print_error "Git user configuration is not set"
      print_info "Please configure your git user name and email:"
      print_info '  git config --global user.name "Your Name"'
      print_info '  git config --global user.email "your.email@example.com"'
      return 1
    fi
    return 0
  }

  # Check if GitHub CLI is authenticated
  check_github_auth() {
    if ! check_github_cli; then
      return 1
    fi

    if ! gh auth status &>/dev/null; then
      print_warning "GitHub CLI is not authenticated"
      print_info "Starting GitHub authentication process..."

      if gh auth login; then
        print_success "GitHub CLI authentication completed"
        return 0
      else
        print_error "GitHub CLI authentication failed"
        return 1
      fi
    fi

    print_success "GitHub CLI is authenticated"
    return 0
  }

  # Create project directory and navigate to it
  setup_project_directory() {
    local project_name="$1"

    if [[ ! -d $project_name ]]; then
      print_info "Creating project directory: $project_name"
      mkdir -p "$project_name"
    fi

    cd "$project_name" || return 1
  }

  # Initialize git repository
  initialize_git_repo() {
    if [[ ! -d ".git" ]]; then
      print_info "Initializing git repository..."
      git init
      print_success "Git repository initialized"
    else
      print_warning "Git repository already exists"
    fi
  }

  # Create README.md file
  create_readme() {
    local project_name="$1"
    local description="$2"

    if [[ ! -f "README.md" ]]; then
      print_info "Creating README.md..."
      local template_path="$INSTALL_DIR/templates/README.md"

      if [[ -f $template_path ]]; then
        cp "$template_path" "README.md"
        # Replace placeholders in the template
        sed -i '' "s/PROJECT_NAME/$project_name/g" "README.md"
        sed -i '' "s/PROJECT_DESCRIPTION/${description:-A new project}/g" "README.md"
        print_success "README.md created from template"
      else
        print_error "README template not found at $template_path"
        print_error "Template may have been moved or deleted"
        return 1
      fi
    fi
  }

  # Create .gitignore file
  create_gitignore() {
    if [[ ! -f ".gitignore" ]]; then
      print_info "Creating .gitignore..."
      local template_path="$INSTALL_DIR/templates/gitignore"

      if [[ -f $template_path ]]; then
        cp "$template_path" ".gitignore"
        print_success ".gitignore created from template"
      else
        print_error "Gitignore template not found at $template_path"
        print_error "Template may have been moved or deleted"
        return 1
      fi
    fi
  }

  # Create initial commit and push
  create_initial_commit() {
    print_info "Creating initial commit and pushing to remote..."

    # Use gcp alias for add, commit, and push in one command
    if gcp "feat: initial project setup

- Add README.md with project structure
- Add comprehensive .gitignore
- Set up basic project foundation"; then
      print_success "Initial commit created and pushed to remote"
    else
      print_error "Failed to create initial commit and push"
      return 1
    fi
  }

  # Interactive prompt for repository details
  prompt_for_repo_details() {
    # Project name
    while true; do
      echo
      read -r "repo_name?Repository name: "
      if [[ -n $repo_name ]]; then
        # Validate repository name (basic GitHub rules)
        if [[ $repo_name =~ ^[a-zA-Z0-9._-]+$ ]]; then
          repo_details[name]="$repo_name"
          break
        else
          print_error "Repository name can only contain alphanumeric characters, dots, dashes, and underscores"
        fi
      else
        print_error "Repository name is required"
      fi
    done

    # Description
    echo
    local repo_description
    read -r "repo_description?Description (optional): "
    repo_details[description]="$repo_description"

    # Visibility
    echo
    print_info "Repository visibility:"
    echo "  1) Private (only you and collaborators) [default]"
    echo "  2) Public (anyone can see)"
    echo "  3) Internal (organization members only)"
    local visibility_choice
    while true; do
      read -r "visibility_choice?Choose visibility [1-3] (default: 1): "
      # Use default if empty
      visibility_choice=${visibility_choice:-1}
      case $visibility_choice in
        1)
          repo_details[visibility]="private"
          break
          ;;
        2)
          repo_details[visibility]="public"
          break
          ;;
        3)
          repo_details[visibility]="internal"
          break
          ;;
        *) print_error "Please choose 1, 2, or 3" ;;
      esac
    done

    # Template options
    echo
    print_info "Template options:"
    echo "  1) Create standard repository [default]"
    echo "  2) Create from existing template repository"
    echo "  3) Create repository to be used as template"
    local template_choice template_repo
    while true; do
      read -r "template_choice?Choose template option [1-3] (default: 1): "
      # Use default if empty
      template_choice=${template_choice:-1}
      case $template_choice in
        1)
          repo_details[template_mode]="none"
          break
          ;;
        2)
          repo_details[template_mode]="from"
          read -r "template_repo?Template repository (owner/repo): "
          repo_details[template_repo]="$template_repo"
          break
          ;;
        3)
          repo_details[template_mode]="as"
          break
          ;;
        *) print_error "Please choose 1, 2, or 3" ;;
      esac
    done

    # Directory location
    echo
    print_info "Project location:"
    echo "  1) Create in new subdirectory ./${repo_details[name]} [default]"
    echo "  2) Create in current directory"
    local location_choice
    while true; do
      read -r "location_choice?Choose location [1-2] (default: 1): "
      # Use default if empty
      location_choice=${location_choice:-1}
      case $location_choice in
        1)
          repo_details[location]="subdirectory"
          break
          ;;
        2)
          repo_details[location]="current"
          break
          ;;
        *) print_error "Please choose 1 or 2" ;;
      esac
    done

    # GitHub features
    echo
    print_info "GitHub repository features:"
    # Always use local README template
    repo_details[add_readme]="false"

    local add_gitignore gitignore_template
    read -r "add_gitignore?Add .gitignore? [Y/n] (default: Y): "
    # Default to Y if empty, convert to lowercase for comparison
    add_gitignore=${add_gitignore:-Y}
    repo_details[add_gitignore]=$([ "${add_gitignore:l}" != "n" ] && echo "true" || echo "false")

    if [[ ${repo_details[add_gitignore]} == "true" ]]; then
      read -r "gitignore_template?Gitignore template (e.g., Node, Python, Go) [blank for general]: "
      repo_details[gitignore_template]="$gitignore_template"
    fi
  }

  # Create GitHub repository using GitHub CLI
  create_github_repo() {
    # Use global repo_details array instead of nameref

    print_info "Creating GitHub repository: ${repo_details[name]}"

    # Build gh repo create command
    local gh_command="gh repo create ${repo_details[name]}"

    # Add visibility flag
    gh_command+=" --${repo_details[visibility]}"

    # Add description if provided
    if [[ -n ${repo_details[description]} ]]; then
      gh_command+=" --description \"${repo_details[description]}\""
    fi

    # Handle template creation (FROM template)
    if [[ ${repo_details[template_mode]} == "from" && -n ${repo_details[template_repo]} ]]; then
      gh_command+=" --template ${repo_details[template_repo]}"
    fi

    # Add GitHub-managed files only if not using a template
    if [[ ${repo_details[template_mode]} != "from" ]]; then
      # Never add GitHub README - always use local template

      if [[ ${repo_details[add_gitignore]} == "true" ]]; then
        if [[ -n ${repo_details[gitignore_template]} ]]; then
          gh_command+=" --gitignore ${repo_details[gitignore_template]}"
        fi
      fi
    fi

    # Clone the repository locally
    gh_command+=" --clone"

    # Execute the command
    print_info "Running: $gh_command"
    if eval "$gh_command"; then
      print_success "GitHub repository created successfully"
      return 0
    else
      print_error "Failed to create GitHub repository"
      return 1
    fi
  }

  # Setup remote origin (if not already done by --clone)
  setup_remote_origin() {
    local repo_name="$1"

    # Check if origin already exists
    if git remote get-url origin &>/dev/null; then
      print_success "Remote origin already configured"
      return 0
    fi

    # Get the authenticated user's GitHub username
    local github_user
    github_user=$(gh api user --jq '.login' 2>/dev/null || true)

    if [[ -n $github_user ]]; then
      local repo_url="git@github.com:${github_user}/${repo_name}.git"
      print_info "Adding remote origin: $repo_url"
      git remote add origin "$repo_url"
      print_success "Remote origin configured"
    else
      print_warning "Could not determine GitHub username. Remote origin not configured."
      return 1
    fi
  }

  # Handle template repository setup
  handle_template_setup() {
    # Use global repo_details array
    if [[ ${repo_details[template_mode]} == "as" ]]; then
      print_info "Repository will be marked as template..."
      print_warning "GitHub CLI doesn't support marking repositories as templates during creation"
      print_info "You'll need to manually enable this in GitHub settings after creation"

      # Store template instructions for later display
      repo_details[needs_template_setup]="true"
    fi
  }

  # Display next steps
  show_next_steps() {
    # Use global repo_details array
    print_info "Project initialized in: $(pwd)"
    print_info "GitHub repository: https://github.com/$(gh api user --jq '.login' 2>/dev/null)/${repo_details[name]}"

    echo
    print_info "Next steps:"

    # Show template setup instructions if needed
    if [[ ${repo_details[needs_template_setup]:-false} == "true" ]]; then
      echo "  1. Mark repository as template:"
      echo "     - Visit: https://github.com/$(gh api user --jq '.login' 2>/dev/null)/${repo_details[name]}/settings"
      echo "     - Check 'Template repository' option"
      echo "  2. Make changes and commit: gcp 'feat: your changes'"
      echo "  3. Create pull requests: pr"
    else
      echo "  1. Make changes and commit: gcp 'feat: your changes'"
      echo "  2. Create pull requests: pr"
    fi

    echo
    print_success "Repository setup complete!"
  }

  # Initialize a new git project with GitHub integration
  git_init_main() {
    # Check prerequisites
    if ! check_git_user_config || ! check_github_auth; then
      return 1
    fi

    print_header "GitHub Repository Creation Wizard"

    # Declare associative array for repository details
    typeset -A repo_details

    # Initialize template setup flag to prevent "parameter not set" errors
    repo_details[needs_template_setup]="false"

    # Get repository details from user
    prompt_for_repo_details

    echo
    print_header "Creating Repository: ${repo_details[name]}"

    # Note: For subdirectory mode, gh repo create --clone will handle directory creation
    # For current directory mode, we're already in the right place

    # Handle template setup notifications
    handle_template_setup

    # Create GitHub repository (this will clone it locally)
    if ! create_github_repo; then
      print_error "Failed to create GitHub repository"
      return 1
    fi

    # Navigate to the cloned directory (only needed for subdirectory mode)
    if [[ ${repo_details[location]} == "subdirectory" ]]; then
      cd "${repo_details[name]}" || {
        print_error "Failed to navigate to cloned repository"
        return 1
      }
    fi

    # If not using a template, create local files
    if [[ ${repo_details[template_mode]} != "from" ]]; then
      # Always create README from local template
      create_readme "${repo_details[name]}" "${repo_details[description]}"

      if [[ ${repo_details[add_gitignore]} == "false" ]]; then
        create_gitignore
      fi

      # Always create initial commit since we always add local files
      create_initial_commit
    fi

    # Show next steps and completion
    show_next_steps

    print_info "Function completed successfully. You are now in: $(pwd)"
    return 0
  }

  # Execute the main function
  git_init_main "$@"
}
