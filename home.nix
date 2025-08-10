# This is a Home Manager module that defines user-specific configuration
# Home Manager manages dotfiles, user packages, and user-level services
# The function signature receives:
# - config: the final merged home configuration
# - pkgs: the nixpkgs package set for installing user packages
# - inputs: the flake inputs passed from flake.nix (includes mac-app-util, etc.)
# - ...: any additional arguments
{ config, pkgs, inputs, ... }:

# Return an attribute set that defines our user configuration
{
  # Basic user identification - must match the system user
  # This tells Home Manager which user account to manage
  home.username = "shanepadgett";

  # The user's home directory path
  # This should match the home directory defined in darwin.nix
  # Home Manager will manage files and configurations within this directory
  home.homeDirectory = "/Users/shanepadgett";

  # Home Manager state version for compatibility tracking
  # This should match the Home Manager version when you first set it up
  # Format is "YY.MM" (year.month) - don't change after initial setup
  # It helps Home Manager handle breaking changes between versions
  home.stateVersion = "25.05";

  # Import additional Home Manager modules
  # This extends Home Manager's capabilities with extra functionality
  imports = [
    # mac-app-util provides macOS-specific utilities for Home Manager
    # Helps with managing macOS applications and system integration
    inputs.mac-app-util.homeManagerModules.default
  ];

  # Manage dotfiles by copying them to the home directory
  # home.file creates symbolic links or copies files to specific locations
  # The key (".gitconfig") becomes the filename in the home directory
  home.file.".gitconfig".source = ./config/gitconfig;
  # This copies ./config/gitconfig to ~/.gitconfig
  # Alternative: you could use home.file.".gitconfig".text = "..." for inline content

  # Enable and configure user programs
  # These are user-level installations and configurations

  # Enable Git version control system for this user
  # This installs git and provides Home Manager options for configuration
  # You can add git.userName, git.userEmail, etc. here
  programs.git.enable = true;

  # Enable Visual Studio Code for this user
  # This installs VS Code and allows Home Manager to manage its configuration
  # You can add extensions, settings, keybindings, etc. through Home Manager
  programs.vscode.enable = true;
}
