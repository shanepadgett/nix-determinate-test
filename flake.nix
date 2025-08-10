# flake.nix
{
  description = "Universal nix-darwin config for all Macs";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nix-darwin = {
      url = "github:LnL7/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs@{ self, nix-darwin, nixpkgs }:
    let
      configuration = { pkgs, ... }: {
        nix.enable = false;
        nixpkgs.hostPlatform = "aarch64-darwin";

        users.users.shanepadgett = {
          home = "/Users/shanepadgett";
        };

        programs.zsh.enable = true;
        environment.systemPackages = with pkgs; [
          git
          bat
          ripgrep
        ];
        system.stateVersion = 6;
      };
    in {
      darwinConfigurations.default = nix-darwin.lib.darwinSystem {
        modules = [ configuration ];
      };
    };
}
