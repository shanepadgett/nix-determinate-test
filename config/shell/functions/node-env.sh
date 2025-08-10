#!/bin/zsh

# Helper functions for managing NODE_ENV without breaking Electron apps

# Set NODE_ENV for current shell session
node-env() {
  if [[ $# -eq 0 ]]; then
    echo "Current NODE_ENV: ${NODE_ENV:-not set}"
    echo "Usage: node-env [development|production|test]"
    return 0
  fi

  export NODE_ENV="$1"
  echo "NODE_ENV set to: $NODE_ENV"
}

# Run a command with specific NODE_ENV
with-node-env() {
  if [[ $# -lt 2 ]]; then
    echo "Usage: with-node-env <environment> <command>"
    echo "Example: with-node-env development npm start"
    return 1
  fi

  local env="$1"
  shift
  NODE_ENV="$env" "$@"
}

# Aliases for common use cases
alias dev-env='node-env development'
alias prod-env='node-env production'
alias test-env='node-env test'
alias clear-env='unset NODE_ENV && echo "NODE_ENV cleared"'

# Run npm/yarn commands with development environment
alias npm-dev='with-node-env development npm'
alias yarn-dev='with-node-env development yarn'
alias pnpm-dev='with-node-env development pnpm'
