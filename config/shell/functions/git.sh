#!/bin/zsh
# Git-related shell functions

# Check if git user configuration is set
check_git_user_config() {
  local git_name
  local git_email
  git_name=$(git config user.name 2>/dev/null)
  git_email=$(git config user.email 2>/dev/null)

  if [ -z "$git_name" ] || [ -z "$git_email" ]; then
    echo "Error: Git user configuration is not set"
    echo "Please configure your git user name and email:"
    echo '  git config --global user.name "Your Name"'
    echo '  git config --global user.email "your.email@example.com"'
    return 1
  fi
  return 0
}

# Git commit and push function
gcp() {
  if [ -z "$1" ]; then
    echo "Error: Commit message required"
    echo 'Usage: gcp "commit message"'
    return 1
  fi

  # Check if git user configuration is set
  if ! check_git_user_config; then
    return 1
  fi

  git add --all && git commit -m "$1" && git push
}
