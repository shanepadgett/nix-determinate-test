# nix-determinate-test

## Getting Started

Bootstrap:
```zsh
curl -fsSL https://raw.githubusercontent.com/shanepadgett/nix-determinate-test/main/install.sh | zsh
```

Apply the config (nix-darwin not install)
```zsh
sudo nix run nix-darwin -- switch --flake .#default
```

Rebuild and apply (nix-darwin installed)
```zsh
sudo darwin-rebuild switch --flake .#default
```

Uninstall nix
```zsh
/nix/nix-installer uninstall
```
