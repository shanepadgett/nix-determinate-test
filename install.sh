#!/bin/bash

set -e  # Exit on any error

echo "Starting installation process..."

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to print colored output
print_step() {
    echo -e "\n\033[1;34m==> $1\033[0m"
}

print_success() {
    echo -e "\033[1;32m✓ $1\033[0m"
}

print_error() {
    echo -e "\033[1;31m✗ $1\033[0m"
}

if [ ! -t 0 ] && [ -e /dev/tty ]; then
  print_step "Attaching to your terminal for interactive prompts…"
  exec </dev/tty
fi

print_step "Installing Homebrew..."
if command_exists brew; then
    print_success "Homebrew is already installed"
else
    sudo -v
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

    # Add Homebrew to PATH for the current session
    if [[ -f "/opt/homebrew/bin/brew" ]]; then
        eval "$(/opt/homebrew/bin/brew shellenv)"
    elif [[ -f "/usr/local/bin/brew" ]]; then
        eval "$(/usr/local/bin/brew shellenv)"
    fi

    print_success "Homebrew installed successfully"
fi

print_step "Installing Nix with Determinate Systems installer..."
if command_exists nix; then
    print_success "Nix is already installed"
else
    curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install --determinate --no-confirm --force

    # Source the nix profile to make nix available in current session
    if [[ -f "/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh" ]]; then
        source /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
    fi

    print_success "Nix installed successfully"
fi

print_step "Cloning the repository..."
REPO_URL="https://github.com/shanepadgett/nix-determinate-test.git"
REPO_DIR="nix-determinate-test"

if [[ -d "$REPO_DIR" ]]; then
    print_success "Repository directory already exists"
    cd "$REPO_DIR"
    git pull origin main || true  # Update if possible, but don't fail if it can't
else
    git clone "$REPO_URL"
    cd "$REPO_DIR"
    print_success "Repository cloned successfully"
fi

print_step "Applying nix-darwin configuration..."
if command_exists darwin-rebuild; then
    sudo darwin-rebuild switch --flake .#default
else
    sudo nix run nix-darwin -- switch --flake .#default
fi

print_success "Installation completed successfully!"
echo -e "\n\033[1;33m📝 Next steps:\033[0m"
echo "• You may need to restart your terminal or source your shell profile"
echo "• To rebuild the configuration in the future, use:"
echo "  sudo darwin-rebuild switch --flake .#default"
echo "• To uninstall Nix later, use:"
echo "  /nix/nix-installer uninstall"
