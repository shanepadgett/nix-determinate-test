# nix-determinate-test

A test repository for experimenting with Nix configurations and setups, featuring a comprehensive shell utilities package.

## Features

- **macOS Configuration**: Complete nix-darwin setup with home-manager integration
- **Shell Utilities**: Comprehensive collection of development utilities built with Nix
- **Reproducible Environment**: Declarative configuration for consistent development setup

## Shell Utilities

This repository includes a complete shell utilities package in `shell-utils/` that provides:

- **Git Utilities**: `gcp` for quick commit and push workflows
- **Repository Management**: `delete-repo` for safe repository deletion
- **Docker Utilities**: `docker-cleanup` for comprehensive Docker environment cleanup
- **Node.js Environment**: `node-env`, `with-node-env`, and convenience aliases for NODE_ENV management

See [shell-utils/README.md](shell-utils/README.md) for detailed documentation.

## Getting Started

Bootstrap:
```zsh
curl -fsSL https://raw.githubusercontent.com/shanepadgett/nix-determinate-test/main/install.sh | bash
```

Apply the config (nix-darwin not install)
```zsh
sudo nix run nix-darwin -- switch --flake .#default
```

Rebuild and apply (nix-darwin installed)
```zsh
sudo darwin-rebuild switch --flake .#default
```

## Using Shell Utilities

After applying the configuration, the shell utilities will be available in your PATH:

```bash
# Git workflow
gcp "Add new feature"

# Node.js environment management
node-env development
with-node-env production npm start

# Docker cleanup
docker-cleanup

# Repository management
delete-repo old-project
```

## Testing

Test that all utilities build correctly:

```bash
nix build .#default
nix run ./shell-utils#test
```

## Uninstall

Uninstall nix
```zsh
sudo darwin-uninstaller
/nix/nix-installer uninstall
```
