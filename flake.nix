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
      lib = nixpkgs.lib;
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

      apps = forAllSystems (system: {
        default = {
          type = "app";
          program = "${self.packages.${system}.default}/bin/finamp";
        };
        finamp = {
          type = "app";
          program = "${self.packages.${system}.default}/bin/finamp";
        };
      });

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
