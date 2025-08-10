# This is a Nix flake - a modern way to define reproducible Nix configurations
# Flakes provide a standardized way to manage dependencies and outputs
{
  # Human-readable description of what this flake does
  # This appears when you run 'nix flake show' or 'nix flake metadata'
  description = "Universal nix-darwin config for all Macs with shell utilities";

  # The 'inputs' section declares all external dependencies this flake needs
  # These are like dependencies in package.json or requirements.txt
  inputs = {
    # nixpkgs is the main package repository for Nix
    # We're using the unstable branch which gets the latest packages
    # Format: "github:owner/repo/branch" or "github:owner/repo"
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

    # nix-darwin provides macOS-specific system configuration capabilities
    # It's like NixOS but for macOS - manages system settings, services, etc.
    nix-darwin = {
      url = "github:LnL7/nix-darwin";
      # 'follows' means use the same nixpkgs version as our main input
      # This prevents version conflicts and reduces download size
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # home-manager manages user-specific configurations and dotfiles
    # It handles things like shell configs, editor settings, user packages
    home-manager = {
      url = "github:nix-community/home-manager";
      # Again, use the same nixpkgs to avoid conflicts
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # mac-app-util provides utilities for managing macOS applications
    # Helps with app installation and management on macOS
    mac-app-util = {
      url = "github:hraban/mac-app-util";
      # Note: no 'follows' here, so it uses its own nixpkgs version
    };

    nix-vscode-extensions = {
      url = "github:nix-community/nix-vscode-extensions";
    };
  };

  # The 'outputs' function defines what this flake produces
  # It receives all inputs as arguments and returns an attribute set
  # The '@' syntax captures all inputs in the 'inputs' variable while also
  # destructuring specific ones (self, nix-darwin, etc.) for easy access
  outputs = inputs@{ self, nix-darwin, nixpkgs, home-manager, mac-app-util, ... }:
  let
    # Define supported systems
    systems = [ "x86_64-darwin" "aarch64-darwin" "x86_64-linux" "aarch64-linux" ];

    # Helper to generate outputs for each system
    forAllSystems = nixpkgs.lib.genAttrs systems;
  in
  {
    # Expose shell utilities as packages for each system
    packages = forAllSystems (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        shellUtils = import ./shell-utils { inherit pkgs; };
      in
      shellUtils // {
        # Provide a combined package with all utilities
        default = pkgs.buildEnv {
          name = "shell-utils";
          paths = builtins.attrValues shellUtils;
        };
      }
    );

    # darwinConfigurations defines system configurations for macOS
    # 'default' is the name of this configuration - you could have multiple
    # You'd activate this with: darwin-rebuild switch --flake .#default
    darwinConfigurations.default = nix-darwin.lib.darwinSystem {
      # modules is a list of configuration modules to combine
      # Each module contributes settings to the final system configuration
      modules = [
        # Import our main system configuration from darwin.nix
        # This file contains system-wide settings like packages, services
        # Pass inputs to darwin.nix so it can access nix-vscode-extensions
        { _module.args = { inherit inputs; }; }
        ./darwin.nix

        # Add home-manager as a darwin module
        # This integrates user configuration management into system config
        home-manager.darwinModules.home-manager

        # Inline module to configure home-manager specifically
        {
          # Configure home-manager for the user 'shanepadgett'
          # Import user configuration from home.nix
          home-manager.users.shanepadgett = import ./home.nix;

          # Use system-wide package definitions instead of user-specific ones
          # This ensures consistency and reduces duplication
          home-manager.useGlobalPkgs = true;

          # Install packages to user profile instead of system profile
          # This keeps user packages separate from system packages
          home-manager.useUserPackages = true;

          # Pass the flake inputs to home-manager modules
          # This allows home.nix to access things like mac-app-util and shell utilities
          home-manager.extraSpecialArgs = { inherit inputs self; };
        }

        # Include mac-app-util's darwin module for macOS app management
        inputs.mac-app-util.darwinModules.default
      ];
    };
  };
}
