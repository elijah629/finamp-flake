{
  description = "Nix flake packaging Finamp from the redesign branch";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    finamp-src = {
      url = "github:UnicornsOnLSD/finamp?ref=redesign";
      flake = false;
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      finamp-src,
    }:
    let
      inherit (nixpkgs) lib;
      supportedSystems = [ "x86_64-linux" ];
      forAllSystems = lib.genAttrs supportedSystems;
      mkPkgs = system: import nixpkgs { inherit system; };
      mkFinamp =
        system:
        (mkPkgs system).callPackage ./package.nix {
          src = finamp-src;
        };
    in
    {
      packages = forAllSystems (system: {
        default = mkFinamp system;
        finamp = mkFinamp system;
      });

      checks = forAllSystems (system: {
        default = self.packages.${system}.default;
        finamp = self.packages.${system}.finamp;
      });

      apps = forAllSystems (
        system:
        let
          pkgs = mkPkgs system;

          updateFinamp = pkgs.writeShellApplication {
            name = "update-finamp";

            runtimeInputs = [
              pkgs.curl
              pkgs.jq
              pkgs.yq-go
              pkgs.nix
              pkgs.python3
              pkgs.nix-prefetch-git
            ];

            text = ''
              exec bash ./update.sh
            '';
          };
        in
        {
          default = {
            type = "app";
            program = "${self.packages.${system}.default}/bin/finamp";
          };

          finamp = {
            type = "app";
            program = "${self.packages.${system}.default}/bin/finamp";
          };

          update-finamp = {
            type = "app";
            program = "${updateFinamp}/bin/update-finamp";
          };
        }
      );

      overlays.default =
        final: prev:
        let
          system = prev.stdenv.hostPlatform.system;
        in
        lib.optionalAttrs (builtins.hasAttr system self.packages) {
          finamp = self.packages.${system}.default;
        };
    };
}
