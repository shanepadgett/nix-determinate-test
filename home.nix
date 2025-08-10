{ inputs }:

{ pkgs, ... }:
{
  imports = [ inputs.mac-app-util.homeManagerModules.default ];

  home.stateVersion = "25.05";
  nixpkgs.config.allowUnfree = true;

  home.file.".gitconfig".source = ./config/gitconfig;

  programs.git.enable = true;
  programs.vscode.enable = true;
}
