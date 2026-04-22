# Finamp Nix Flake

Standalone flake that packages [Finamp](https://github.com/UnicornsOnLSD/finamp) from the `redesign` branch for Linux.

Current scope:

- platform: `x86_64-linux`
- source: GitHub `UnicornsOnLSD/finamp`, branch `redesign`
- package output: `packages.x86_64-linux.default`

## Use Directly

Run without installing:

```bash
nix run github:elijah629/finamp-flake#finamp
```

Build locally:

```bash
nix build .#finamp
./result/bin/finamp
```

## Import Into Another Flake

Add input:

```nix
inputs.finamp-flake.url = "github:elijah629/finamp-flake";
```

Use package directly:

```nix
environment.systemPackages = [
  inputs.finamp-flake.packages.${pkgs.system}.default
];
```

Or use overlay:

```nix
nixpkgs.overlays = [
  inputs.finamp-flake.overlays.default
];

environment.systemPackages = [
  pkgs.finamp
];
```

## Updating To Newer `redesign`

This repo pins upstream in `flake.lock`.

Refresh everything:

```bash
./update.sh
```

This repo also includes:

- CI build workflow for pushes and pull requests
- scheduled GitHub Action that refreshes the upstream `redesign` pin and opens a PR

## GitHub Repo Settings

For the auto-update workflow to open PRs, enable:

- Settings → Actions → General → Workflow permissions
- select `Read and write permissions`
- allow GitHub Actions to create pull requests
