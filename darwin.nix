# This is a nix-darwin module that defines system-wide configuration for macOS
# The function signature receives three arguments:
# - config: the final merged configuration (useful for referencing other options)
# - pkgs: the nixpkgs package set (contains all available packages)
# - inputs: the flake inputs (needed for nix-vscode-extensions overlay)
# - ...: any additional arguments (we don't use them here, hence the ellipsis)
{ config, pkgs, inputs, ... }:

# Return an attribute set that defines our system configuration
{
  # Disable the Nix daemon - useful if you're using Determinate Systems installer
  # or want to manage Nix differently. Set to true if you want nix-darwin to manage Nix
  nix.enable = false;

  # Specify the target platform architecture
  # "aarch64-darwin" = Apple Silicon Macs (M1, M2, M3, etc.)
  # Use "x86_64-darwin" for Intel Macs
  nixpkgs.hostPlatform = "aarch64-darwin";

  # Configure nixpkgs overlays to extend available packages
  # The nix-vscode-extensions overlay provides access to VSCode marketplace extensions
  nixpkgs.overlays = [
    inputs.nix-vscode-extensions.overlays.default
  ];

  # Allow installation of proprietary/unfree software
  # Many useful applications (like VS Code, Chrome) require this
  # Set to false if you want only open-source software
  nixpkgs.config.allowUnfree = true;

  # Set the primary user for this system
  # This affects various system behaviors and defaults
  system.primaryUser = "shanepadgett";

  # Define user accounts on the system
  # This creates/manages the user account at the system level
  users.users.shanepadgett = {
    # The username for login and system identification
    name = "shanepadgett";
    # The user's home directory path
    # On macOS, this is typically /Users/username
    home = "/Users/shanepadgett";
  };

  # Enable and configure system programs
  # This makes zsh available system-wide and sets it as a valid shell
  programs.zsh.enable = true;

  # System-wide packages available to all users
  # 'with pkgs;' brings all packages into scope so we can reference them directly
  # These packages are installed to /run/current-system/sw/bin/
  environment.systemPackages = with pkgs; [
    python311
    uv
    bat
    direnv
    eza
    fzf
    gh
    htop
    jq
    ripgrep
    zoxide
  ];

  # Homebrew integration - manages packages not available in nixpkgs
  # Homebrew is still useful for some macOS-specific applications
  homebrew = {
    # Enable Homebrew management through nix-darwin
    # This will install Homebrew if it's not already present
    enable = true;

    # Casks are GUI applications distributed through Homebrew
    # These are typically .app bundles or installer packages
    casks = [
      "1password"
      "1password-cli"
      "brave-browser"
      "bruno"
      "discord"
      "ghostty"
      "logi-options-plus"
      "obsidian"
      "orbstack"
      "raycast"
      "rectangle"
      "voiceink"
      "warp"
      "zed"
    ];

    # Brews are command-line tools and libraries
    # Use this for tools not available in nixpkgs or when you need Homebrew's version
    # brews = [];

    # Cleanup behavior when rebuilding the system
    # "uninstall" removes packages not declared in this config
    # Other options: "none" (no cleanup) or "zap" (more aggressive cleanup)
    onActivation.cleanup = "uninstall";
  };

  system.defaults = {
    # Dock Configuration
    dock = {
      autohide = true;
      autohide-delay = 0.0;
      autohide-time-modifier = 0.5;
      tilesize = 48;
      orientation = "bottom";
      show-recents = false;
      minimize-to-application = true;
      persistent-apps = [
        "/Applications/Brave Browser.app"
        "/Applications/Home Manager Trampolines/Visual Studio Code.app"
        "/Applications/Zed.app"
        "/Applications/Warp.app"
        "/Applications/Bruno.app"
        "/Applications/Obsidian.app"
        "/Applications/1Password.app"
        "/Applications/Discord.app"
        "/Applications/OrbStack.app"
      ];
    };

    # Trackpad Configuration
    trackpad = {
      Clicking = true;
      TrackpadThreeFingerDrag = true;
    };

    # Finder Configuration
    finder = {
      ShowPathbar = true;
      ShowStatusBar = true;
      FXDefaultSearchScope = "SCcf";
      FXEnableExtensionChangeWarning = false;
    };

    # Window Manager Configuration
    WindowManager = {
      EnableStandardClickToShowDesktop = false;
    };

    # Global Domain settings
    NSGlobalDomain = {
      AppleEnableSwipeNavigateWithScrolls = true;
      AppleShowAllExtensions = true;
    };
  };

  # State version for compatibility tracking
  # This should match the nix-darwin version when you first set up the system
  # Don't change this after initial setup unless you know what you're doing
  # It helps nix-darwin handle breaking changes between versions
  system.stateVersion = 6;
}
