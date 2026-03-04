{
  lib,
  flake-parts-lib,
  ...
}:

let
  inherit (flake-parts-lib)
    mkPerSystemOption
    ;
in
{
  options = {
    perSystem = mkPerSystemOption (
      {
        config,
        pkgs,
        sharedBuildAttrs,
        ...
      }:
      {
        options = {
          forge.packages = lib.mkOption {
            type = lib.types.listOf (lib.types.submodule ./builder.nix);
          };
        };

        config = {
          packages =
            let
              applyBuilder = pkg: {
                name = pkg.name;
                value = pkgs.callPackage (
                  # Derivation start
                  { }:
                  pkgs.python3Packages.buildPythonApplication (
                    finalAttrs:
                    {
                      pname = pkg.name;
                      version = pkg.version;
                      format = "pyproject";
                      src = sharedBuildAttrs.pkgSource pkg;
                      patches = pkg.source.patches;
                      build-system = pkg.build.pythonAppBuilder.requirements.build-system;
                      dependencies = pkg.build.pythonAppBuilder.requirements.dependencies;
                      optional-dependencies = pkg.build.pythonAppBuilder.requirements.optional-dependencies;
                      pythonImportsCheck = pkg.build.pythonAppBuilder.importsCheck;
                      pythonRelaxDeps = pkg.build.pythonAppBuilder.relaxDeps;
                      disabledTests = pkg.build.pythonAppBuilder.disabledTests;
                      passthru = sharedBuildAttrs.pkgPassthru pkg finalAttrs.finalPackage;
                      meta = sharedBuildAttrs.pkgMeta pkg;
                    }
                    // pkg.build.extraDrvAttrs
                    // lib.optionalAttrs pkg.build.debug sharedBuildAttrs.debugShellHookAttr
                  )
                  # Derivation end
                ) { };
              };

              enabledPackages = lib.filter (p: p.build.pythonAppBuilder.enable) config.forge.packages;
              pythonAppBuilderPkgs = lib.listToAttrs (map applyBuilder enabledPackages);
            in
            pythonAppBuilderPkgs;
        };
      }
    );
  };
}
