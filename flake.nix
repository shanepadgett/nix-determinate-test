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

        homebrew = {
          enable = true;
          casks = [ "1password" "bruno" ];
          brews = [ "jq" ];
          taps = [ "homebrew/cask-versions" ];
          # onActivation.cleanup = "uninstall";
        };

        system.stateVersion = 6;

        # Home Manager user config
        home-manager.users.shanepadgett = { pkgs, ... }: {
          # Import mac-app-util's Home Manager module here
          imports = [ mac-app-util.homeManagerModules.default ];

          home.stateVersion = "25.05";
          nixpkgs.config.allowUnfree = true;

          home.file.".gitconfig".source = ./config/gitconfig;

          programs.git.enable = true;
          programs.vscode.enable = true;
        };
      };
    in {
      darwinConfigurations.default = nix-darwin.lib.darwinSystem {
        modules = [
          configuration
          home-manager.darwinModules.home-manager
          mac-app-util.darwinModules.default
        ];
      };
    };
}
