{ config, pkgs, inputs, ... }:

{
  home.username = "shanepadgett";
  home.homeDirectory = "/Users/shanepadgett";
  home.stateVersion = "25.05";
  nixpkgs.config.allowUnfree = true;

  # Import mac-app-util's Home Manager module
  imports = [ inputs.mac-app-util.homeManagerModules.default ];

  home.file.".gitconfig".source = ./config/gitconfig;

  programs.git.enable = true;
  programs.vscode.enable = true;
}
