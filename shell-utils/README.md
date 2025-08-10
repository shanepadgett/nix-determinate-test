# Shell Utilities

A collection of useful shell utilities built with Nix `writeShellApplication` for reliable, reproducible command-line tools.

## Features

- **Dependency Management**: Automatic PATH setup for runtime dependencies
- **Error Handling**: Built-in `set -euo pipefail` for safer scripts
- **Syntax Checking**: Automatic shellcheck and bash syntax validation
- **Reproducibility**: Hermetic builds with exact dependency versions
- **Portability**: Works across different systems without external dependencies

## Available Utilities

### Git Utilities

#### `git-init` - Git Project Initialization
Interactive wizard for creating new GitHub repositories with local setup.

```bash
git-init    # Start interactive repository creation wizard
```

**Features:**
- Creates GitHub repository with customizable settings
- Initializes local git repository
- Creates README.md and .gitignore files
- Supports template repositories
- Handles repository visibility (private/public/internal)
- Makes initial commit and pushes to remote
- GitHub CLI integration with authentication

#### `gcp` - Git Commit and Push
Quick git workflow: add all changes, commit with message, and push.

```bash
gcp "Fix bug in user authentication"
gcp "Add new feature for data export"
```

**Features:**
- Validates git user configuration
- Shows changes before committing
- Handles errors gracefully

### Repository Management

#### `delete-repo` - Repository Deletion
Safely delete repositories both locally and on GitHub.

```bash
delete-repo                # Delete current repository
delete-repo my-project     # Delete specified repository
delete-repo -l my-project  # Delete only local repository
delete-repo -r my-project  # Delete only GitHub repository
delete-repo -f my-project  # Force delete without confirmation
```

**Features:**
- GitHub CLI integration
- Safety checks for system directories
- Interactive confirmation prompts
- Handles being inside the repository being deleted

### Docker Utilities

#### `docker-cleanup` - Docker Environment Cleanup
Clean up Docker containers, images, volumes, and networks.

```bash
docker-cleanup           # Interactive cleanup
docker-cleanup -f        # Force cleanup without confirmation
```

**Features:**
- Comprehensive Docker cleanup
- Safety confirmations
- Detailed progress reporting

### Node.js Environment Management

#### `node-env` - NODE_ENV Management
Manage NODE_ENV environment variable for Node.js development.

```bash
node-env                    # Show current NODE_ENV
node-env development        # Set NODE_ENV=development
node-env production         # Set NODE_ENV=production
node-env test              # Set NODE_ENV=test
```

#### `with-node-env` - Run Commands with Specific NODE_ENV
Run commands with a specific NODE_ENV without affecting the shell.

```bash
with-node-env development npm start
with-node-env production node server.js
with-node-env test npm test
```

#### Convenience Aliases

- `dev-env` - Set NODE_ENV to development
- `prod-env` - Set NODE_ENV to production
- `test-env` - Set NODE_ENV to test
- `clear-env` - Unset NODE_ENV
- `npm-dev` - Run npm with development environment
- `yarn-dev` - Run yarn with development environment
- `pnpm-dev` - Run pnpm with development environment

## Installation

### As Part of This Flake

The utilities are automatically available when using this flake's home-manager configuration.

### Standalone Usage

You can use individual utilities from other Nix configurations:

```nix
# In your flake.nix inputs
inputs.shell-utils.url = "github:yourusername/nix-determinate-test";

# In your configuration
home.packages = [
  inputs.shell-utils.packages.${system}.gcp
  inputs.shell-utils.packages.${system}.delete-repo
  # Or all utilities:
  inputs.shell-utils.packages.${system}.default
];
```

### Development

To test utilities during development:

```bash
# Test a specific utility
nix run .#gcp -- "test commit"

# Build all utilities
nix build .#default

# Enter development shell
nix develop
```

## Architecture

### Shared Components

All utilities use shared components from `lib/common.nix`:

- **Colors**: Consistent color output functions
- **GitHub**: GitHub CLI helper functions
- **Git**: Git repository helper functions
- **Validation**: Input validation functions
- **Interaction**: User interaction helpers

### Benefits Over Traditional Shell Scripts

1. **No External Dependencies**: No need to source external files
2. **Portable**: Works across different systems without setup
3. **Versioned**: Can pin specific versions of dependencies
4. **Testable**: Can write proper tests for each utility
5. **Modular**: Easy to enable/disable specific utilities
6. **Safe**: Built-in error handling and validation

## Contributing

1. Add new utilities as `.nix` files in the root directory
2. Update `default.nix` to include the new utility
3. Use shared components from `lib/common.nix` where possible
4. Follow the existing patterns for error handling and user interaction
5. Add documentation to this README

## Migration from Shell Functions

This package replaces traditional shell functions with proper Nix packages:

- ✅ Better dependency management
- ✅ Automatic syntax checking
- ✅ Reproducible builds
- ✅ No external file dependencies
- ✅ Consistent error handling
- ✅ Portable across systems
