{ pkgs }:
let
  callPackage = pkgs.callPackage;
in
{
  # Git utilities
  "git-init" = callPackage ./git-init.nix { };
  gcp = callPackage ./gcp.nix { };

  "rebuild-darwin" = callPackage ./rebuild-darwin.nix { };

  # Repository management
  "delete-repo" = callPackage ./delete-repo.nix { };

  # Docker utilities
  "docker-cleanup" = callPackage ./docker-cleanup.nix { };

  # Node.js environment management
  "node-env" = callPackage ./node-env.nix { };
  "with-node-env" = callPackage ./with-node-env.nix { };

  # Convenience aliases for Node.js environments
  "dev-env" = pkgs.writeShellApplication {
    name = "dev-env";
    text = ''node-env development'';
    runtimeInputs = [ (callPackage ./node-env.nix { }) ];
  };

  "prod-env" = pkgs.writeShellApplication {
    name = "prod-env";
    text = ''node-env production'';
    runtimeInputs = [ (callPackage ./node-env.nix { }) ];
  };

  "test-env" = pkgs.writeShellApplication {
    name = "test-env";
    text = ''node-env test'';
    runtimeInputs = [ (callPackage ./node-env.nix { }) ];
  };

  "clear-env" = pkgs.writeShellApplication {
    name = "clear-env";
    text = ''
      unset NODE_ENV
      echo "NODE_ENV cleared"
    '';
  };

  # Package manager shortcuts with development environment
  "npm-dev" = pkgs.writeShellApplication {
    name = "npm-dev";
    text = ''with-node-env development npm "$@"'';
    runtimeInputs = [
      (callPackage ./with-node-env.nix { })
      pkgs.nodejs
    ];
  };

  "yarn-dev" = pkgs.writeShellApplication {
    name = "yarn-dev";
    text = ''with-node-env development yarn "$@"'';
    runtimeInputs = [
      (callPackage ./with-node-env.nix { })
      pkgs.yarn
    ];
  };

  "pnpm-dev" = pkgs.writeShellApplication {
    name = "pnpm-dev";
    text = ''with-node-env development pnpm "$@"'';
    runtimeInputs = [
      (callPackage ./with-node-env.nix { })
      pkgs.nodePackages.pnpm
    ];
  };
}
