#!/bin/zsh
# Development environment
export PAGER=less
export MANPAGER="less -X"

# Git configuration
# Use nano as git editor for better container/remote compatibility
# VS Code doesn't work well for interactive git operations in containers
if [ -n "$CODESPACES" ] || [ -n "$REMOTE_CONTAINERS" ] || [ -n "$VSCODE_REMOTE" ]; then
  export GIT_EDITOR="nano"
else
  # Use VS Code with --wait flag for proper git integration on local machines
  export GIT_EDITOR="code --wait"
fi

# Better defaults for tools
export RIPGREP_CONFIG_PATH="$HOME/.ripgreprc"

# Development paths
export DEVELOPMENT_HOME="$HOME/Development"
export PERSONAL_HOME="$DEVELOPMENT_HOME/personal"
export OPEN_SOURCE_HOME="$DEVELOPMENT_HOME/open-source"
export EXPERIMENTS_HOME="$DEVELOPMENT_HOME/experiments"
export WORK_HOME="$DEVELOPMENT_HOME/work"

# DIRENV
export DIRENV_LOG_FORMAT=""
