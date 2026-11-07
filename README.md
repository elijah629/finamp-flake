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
- scheduled GitHub Action that refreshes the upstream `redesign` pin and dependency
  hashes every Tuesday and Friday at 08:23 UTC
- updates are committed to the default branch only after `nix flake check` and
  `nix build .#default` succeed; unchanged inputs produce no commit

## GitHub Repo Settings

The update workflow uses the built-in `GITHUB_TOKEN` with `contents: write`.
The default branch must allow GitHub Actions to push commits. No PAT or
auto-merge setting is needed. Use **Actions → Update flake → Run workflow**
to trigger an update manually.

This updates this package repository. A consuming system flake keeps its own
lockfile and must update its `finamp-flake` input to adopt a new revision.
