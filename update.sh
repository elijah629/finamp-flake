#!/usr/bin/env bash

set -euo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
cd "$ROOT"

nix flake update

rev="$(jq -er '.nodes["finamp-src"].locked.rev' flake.lock)"

fetch_git_hashes_script="$(
  nix eval --raw --impure --expr '
    let
      flake = builtins.getFlake (toString ./.);
      pkgs = import flake.inputs.nixpkgs {
        system = builtins.currentSystem;
      };
    in
      pkgs.dart.fetchGitHashesScript
  '
)"

curl --fail --silent --show-error --location \
  "https://raw.githubusercontent.com/UnicornsOnLSD/finamp/${rev}/pubspec.lock" \
  | yq eval --output-format=json --prettyPrint - > pubspec.lock.json

python3 "$fetch_git_hashes_script" \
  --input pubspec.lock.json \
  --output git-hashes.json
