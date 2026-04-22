#!/usr/bin/env nix-shell
#!nix-shell -i bash -p curl jq yq-go nix python3 nix-prefetch-git

set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
cd "$ROOT"

nix flake update

rev="$(jq -r '.nodes["finamp-src"].locked.rev' flake.lock)"
fetch_git_hashes_script="$(
  nix eval --raw --impure --expr '
    let
      flake = builtins.getFlake (toString ./.);
      pkgs = import flake.inputs.nixpkgs { system = builtins.currentSystem; };
    in
    pkgs.dart.fetchGitHashesScript
  '
)"

curl --fail --silent --location \
  "https://raw.githubusercontent.com/UnicornsOnLSD/finamp/${rev}/pubspec.lock" \
  | yq eval --output-format=json --prettyPrint > pubspec.lock.json

python3 "$fetch_git_hashes_script" \
  --input pubspec.lock.json \
  --output git-hashes.json
