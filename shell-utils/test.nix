# Simple test to verify shell utilities build correctly
{ pkgs ? import <nixpkgs> {} }:

let
  shellUtils = import ./default.nix { inherit pkgs; };
in
pkgs.runCommand "shell-utils-test" {
  buildInputs = builtins.attrValues shellUtils;
} ''
  # Test that all utilities are available and have help
  echo "Testing shell utilities..."
  
  # Test gcp
  gcp --help > /dev/null
  echo "✓ gcp help works"
  
  # Test delete-repo
  delete-repo --help > /dev/null
  echo "✓ delete-repo help works"
  
  # Test docker-cleanup
  docker-cleanup --help > /dev/null
  echo "✓ docker-cleanup help works"
  
  # Test node-env
  node-env --help > /dev/null
  echo "✓ node-env help works"
  
  # Test with-node-env
  with-node-env --help > /dev/null
  echo "✓ with-node-env help works"
  
  # Test convenience aliases
  dev-env --help > /dev/null || true  # May not have help
  echo "✓ dev-env available"
  
  echo "All shell utilities passed basic tests!"
  touch $out
''
