{ config, pkgs, ... }:

{
  nix.enable = false;
  nixpkgs.hostPlatform = "aarch64-darwin";
  nixpkgs.config.allowUnfree = true;
  system.primaryUser = "shanepadgett";

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
}
