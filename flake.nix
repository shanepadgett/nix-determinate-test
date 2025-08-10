# flake.nix
{
  description = "Universal nix-darwin config for all Macs";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nix-darwin = {
      url = "github:LnL7/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    mac-app-util = {
      url = "github:hraban/mac-app-util";
    };
  };

  outputs = inputs@{ self, nix-darwin, nixpkgs, home-manager, mac-app-util }:
    let
      configuration = { pkgs, ... }: {
        nix.enable = false;
        nixpkgs.hostPlatform = "aarch64-darwin";
        nixpkgs.config.allowUnfree = true;

        users.users.shanepadgett = {
          name = "shanepadgett";
          home = "/Users/shanepadgett";
        };

        programs.zsh.enable = true;
        environment.systemPackages = with pkgs; [
          git
          bat
          ripgrep
        ];
        system.stateVersion = 6;

        # Add Home Manager module
        home-manager.users.shanepadgett = { ... }: {
          home.stateVersion = "25.05";
          nixpkgs.config.allowUnfree = true;
          # Symlink ~/.gitconfig
          home.file.".gitconfig".source = ./config/gitconfig;
          # Symlink VSCode settings.json
          # home.file.".config/Code/User/settings.json".source = /Users/shanepadgett/path/to/settings.json;
          # Optionally, manage packages and VSCode with home-manager
          programs.git.enable = true;
          programs.vscode.enable = true;
          # ...other home-manager config...
        };
      };
    in {
      darwinConfigurations.default = nix-darwin.lib.darwinSystem {
        modules = [
          configuration
          home-manager.darwinModules.home-manager
          mac-app-util.darwinModules.default
        ];
        home-manager.sharedModules = [
          mac-app-util.homeManagerModules.default
        ];
      };
    };
}
