# nix-determinate-test

## Getting Started

Install nix with determinate
```zsh
curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install --determinate --no-confirm --force
```

Apply the config
```zsh
nix run nix-darwin -- switch --flake github:shanepadgett/nix-determinate-test#default
```

Uninstall nix
```zsh
/nix/nix-installer uninstall
```
