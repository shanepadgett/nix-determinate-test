# This is a Home Manager module that defines user-specific configuration
# Home Manager manages dotfiles, user packages, and user-level services
# The function signature receives:
# - config: the final merged home configuration
# - pkgs: the nixpkgs package set for installing user packages
# - inputs: the flake inputs passed from flake.nix (includes mac-app-util, etc.)
# - self: reference to this flake for accessing shell utilities
# - ...: any additional arguments
{
  config,
  pkgs,
  inputs,
  self,
  ...
}:

# Return an attribute set that defines our user configuration
let
  # Import shell utilities from this flake
  shellUtils = import ./shell-utils { inherit pkgs; };
  # Absolute path to this dotfiles repo for out-of-store symlinks
  dotfiles = "${config.home.homeDirectory}/.dotfiles";
in
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

  # Install shell utilities as user packages
  home.packages =
    with pkgs;
    [
      # Shell utilities from this flake
    ]
    ++ (builtins.attrValues shellUtils);

  # Import additional Home Manager modules
  # This extends Home Manager's capabilities with extra functionality
  imports = [
    # mac-app-util provides macOS-specific utilities for Home Manager
    # Helps with managing macOS applications and system integration
    inputs.mac-app-util.homeManagerModules.default
  ];

  # Manage dotfiles and app configs by symlinking from the repo (out-of-store)
  # Use mkOutOfStoreSymlink so links point directly to files in ~/.dotfiles
  home.file = {
    # Dotfiles in $HOME
    ".gitconfig".source = config.lib.file.mkOutOfStoreSymlink "${dotfiles}/config/tools/gitconfig";
    ".zshrc".source = config.lib.file.mkOutOfStoreSymlink "${dotfiles}/config/shell/zshrc";
    ".bashrc".source = config.lib.file.mkOutOfStoreSymlink "${dotfiles}/config/shell/bashrc";
    ".aliases".source = config.lib.file.mkOutOfStoreSymlink "${dotfiles}/config/shell/aliases";
    ".exports".source = config.lib.file.mkOutOfStoreSymlink "${dotfiles}/config/shell/exports";

    # Tool-specific dotfiles in $HOME
    ".ripgreprc".source = config.lib.file.mkOutOfStoreSymlink "${dotfiles}/config/tools/ripgreprc";

    # Apps that don't follow XDG on macOS (VS Code)
    # This will create ~/Library/Application Support/Code/User/settings.json
    "Library/Application Support/Code/User/settings.json".source =
      config.lib.file.mkOutOfStoreSymlink "${dotfiles}/config/tools/vscode/settings.json";
  };

  # XDG-configured apps (files live under ~/.config)
  xdg.configFile = {
    "direnv/direnv.toml".source =
      config.lib.file.mkOutOfStoreSymlink "${dotfiles}/config/tools/direnv/direnv.toml";
    "ghostty/config".source =
      config.lib.file.mkOutOfStoreSymlink "${dotfiles}/config/tools/ghostty/config";
    "zed/settings.json".source =
      config.lib.file.mkOutOfStoreSymlink "${dotfiles}/config/tools/zed/settings.json";
    "zoxide/config.toml".source =
      config.lib.file.mkOutOfStoreSymlink "${dotfiles}/config/tools/zoxide/config.toml";

    # Claude app/editor configs (adjust if your install expects a different path)
    "claude/mcp.json".source =
      config.lib.file.mkOutOfStoreSymlink "${dotfiles}/config/tools/claude/mcp.json";
    "claude/settings.json".source =
      config.lib.file.mkOutOfStoreSymlink "${dotfiles}/config/tools/claude/settings.json";
  };

  # Enable and configure user programs
  # These are user-level installations and configurations

  # Enable Git version control system for this user
  # This installs git and provides Home Manager options for configuration
  # You can add git.userName, git.userEmail, etc. here
  programs.git.enable = true;

  # Enable direnv for automatic environment loading
  # This provides better integration than manual shell hooks
  programs.direnv = {
    enable = true;
    # Enable nix-direnv for better Nix flake support and caching
    nix-direnv.enable = true;
  };

  # Enable Visual Studio Code for this user
  # This installs VS Code and allows Home Manager to manage its configuration
  # You can add extensions, settings, keybindings, etc. through Home Manager
  programs.vscode = {
    enable = true;
    package = pkgs.vscode;
    profiles.default.extensions =
      with pkgs.vscode-extensions;
      [
        # Extensions from nixpkgs (curated) - these are confirmed available
        editorconfig.editorconfig
        github.github-vscode-theme
      ]
      ++ [
        # Extensions from marketplace (using full path)
        # Note: These will be available after the overlay is properly loaded
        pkgs.vscode-marketplace.augment.vscode-augment
        pkgs.vscode-marketplace.anthropic.claude-code
        pkgs.vscode-marketplace.kilocode.kilo-code
        pkgs.vscode-marketplace.mkhl.direnv
        pkgs.vscode-marketplace.arrterian.nix-env-selector
        pkgs.vscode-marketplace.jnoortheen.nix-ide
        pkgs.vscode-marketplace.davidanson.vscode-markdownlint
      ];
  };
}
