{
  description = "Core flake exposing tools and utilities provided by SnapSettle";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    dashboard.url = "github:snapsettle/dashboard";
    dashboard.inputs.nixpkgs.follows = "nixpkgs";

    nix-helpers.url = "github:snapsettle/nix-helpers";
    nix-helpers.inputs.nixpkgs.follows = "nixpkgs";

    gitgetter.url = "github:snapsettle/gitgetter";
    gitgetter.inputs.nixpkgs.follows = "nixpkgs";

    treefmt-nix.url = "github:numtide/treefmt-nix";
    treefmt-nix.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs =
    {
      self,
      nixpkgs,
      dashboard,
      nix-helpers,
      gitgetter,
      treefmt-nix,
      ...
    }:
    let
      systems = [
        "x86_64-linux"
        "aarch64-linux"
      ];

      eachSystem = f: nixpkgs.lib.genAttrs systems (system: f (import nixpkgs { inherit system; }));

      treefmtConfig = eachSystem (
        pkgs:
        treefmt-nix.lib.evalModule pkgs {
          projectRootFile = "flake.nix";
          programs.nixfmt.enable = true; # Enables the standard nixfmt-rfc-style formatter
        }
      );
    in
    {
      formatter = eachSystem (
        pkgs: treefmtConfig.${pkgs.stdenv.hostPlatform.system}.config.build.wrapper
      );

      nixosModules = {
        dashboard = dashboard.nixosModules.default;
        nix-helpers = nix-helpers.nixosModules.default;
        gitgetter = gitgetter.nixosModules.default;

        default = {
          imports = [
            dashboard.nixosModules.default
            nix-helpers.nixosModules.default
            gitgetter.nixosModules.default
          ];
        };
      };

      packages = nixpkgs.lib.genAttrs systems (system: {
        dashboard = dashboard.packages.${system}.default;
        nix-helpers = nix-helpers.packages.${system}.default;
        gitgetter = gitgetter.packages.${system}.default;
      });
    };
}
