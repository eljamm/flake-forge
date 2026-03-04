{
  config,
  lib,
  flake-parts-lib,
  ...
}:

let
  inherit (flake-parts-lib) mkPerSystemOption;
in
{
  options = {
    perSystem = mkPerSystemOption (
      { config, pkgs, ... }:
      {
        options.forge_2 = {
          repositoryUrl = lib.mkOption {
            type = lib.types.str;
            default = "github:imincik/nix-forge";
            description = ''
              Nix Forge repository URL.
            '';
            example = "github:imincik/nix-forge";
          };

          recipeDirs = {
            packages = lib.mkOption {
              type = lib.types.nullOr lib.types.str;
              default = "recipes_2/packages";
              description = ''
                Directory containing package recipe files.
                Each recipe should be a recipe.nix file in a subdirectory
                (e.g., recipes_2/packages/hello/recipe.nix).

                Set to null to disable automatic package recipe loading.
              '';
              example = "recipes_2/packages";
            };

            apps = lib.mkOption {
              type = lib.types.nullOr lib.types.str;
              default = "recipes_2/apps";
              description = ''
                Directory containing app recipe files.
                Each recipe should be a recipe.nix file in a subdirectory
                (e.g., recipes_2/apps/my-app/recipe.nix).

                Set to null to disable automatic app recipe loading.
              '';
              example = "recipes_2/apps";
            };
          };
        };
      }
    );
  };
}
