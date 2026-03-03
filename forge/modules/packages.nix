{
  inputs,
  config,
  lib,
  flake-parts-lib,
  ...
}:

let
  inherit (flake-parts-lib) mkPerSystemOption;
in
{
  imports = [
    ./assertions-warnings.nix
    ./builders/shared.nix
    ./builders/standard-builder.nix
    ./builders/python-app
    ./builders/python-package-builder.nix
  ];

  options = {
    perSystem = mkPerSystemOption (
      { config, pkgs, ... }:
      {
        options = {
          forge = {
            packagesFilter = lib.mkOption {
              internal = true;
              type = lib.types.attrsOf (lib.types.listOf lib.types.str);
              default = { };
              description = ''
                Defines which configuration options are relevant for each builder type.

                Used for filtering options documentation to show only builder-specific
                options in the generated documentation.
              '';
            };

            packages = lib.mkOption {
              default = [ ];
              description = ''
                List of packages to include in forge.

                Each package uses one of the available builders.
                Only one builder can be enabled per package by setting build.<builder>.enable = true.
              '';
              type = lib.types.listOf (lib.types.submodule ./package.nix);
            };
          };
        };

        # Config section is now provided by builder modules
        config =
          let
            cfg = config.forge.packages;

            # Process warnings: filter to get active warnings (condition = true), then show them
            activeWarnings = lib.filter (x: x.condition) config.warnings;
            showWarnings = lib.foldr (w: acc: lib.warn w.message acc) true activeWarnings;

            # Process assertions: filter to get failed assertions (condition = false)
            failedAssertions = lib.filter (x: !x.condition) config.assertions;
            assertionMessages = lib.concatMapStringsSep "\n" (x: "- ${x.message}") failedAssertions;
          in
          {
            # Collect warnings from packages
            warnings = lib.flatten (
              map (pkg: {
                condition = pkg.source.hash == "";
                message = ''
                  Package '${pkg.name}': source.hash is empty.
                  Correct hash will be printed in the error message when package is built.
                '';
              }) cfg
            );

            # Collect assertions from packages
            assertions = lib.flatten (
              map (pkg: [
                {
                  condition = !(pkg.source.git == null && pkg.source.url == null && pkg.source.path == null);
                  message = ''
                    Package '${pkg.name}': one of sources options must be defined.
                    Available options: source.git, source.url, or source.path.
                  '';
                }
                {
                  condition =
                    pkg.build.standardBuilder.enable
                    || pkg.build.pythonAppBuilder.enable
                    || pkg.build.pythonPackageBuilder.enable;
                  message = ''
                    Package '${pkg.name}': one of builder options must be enabled.
                    Available options: build.standardBuilder, build.pythonAppBuilder, or build.pythonPackageBuilder.'';
                }
              ]) cfg
            );

            forge.packagesFilter = lib.mkDefault {
              standardBuilder = [
                "packages.*.name"
                "packages.*.version"
                "packages.*.source.git"
                "packages.*.source.patches"
                "packages.*.build.standardBuilder.enable"
                "packages.*.build.standardBuilder.requirements.native"
                "packages.*.build.standardBuilder.requirements.build"
                "packages.*.test.script"
              ];
              pythonAppBuilder = [
                "packages.*.name"
                "packages.*.version"
                "packages.*.source.git"
                "packages.*.source.patches"
                "packages.*.build.pythonAppBuilder.enable"
                "packages.*.build.pythonAppBuilder.requirements.build-system"
                "packages.*.build.pythonAppBuilder.requirements.dependencies"
                "packages.*.build.pythonAppBuilder.requirements.optional-dependencies"
                "packages.*.build.pythonAppBuilder.importsCheck"
                "packages.*.build.pythonAppBuilder.relaxDeps"
                "packages.*.build.pythonAppBuilder.disabledTests"
                "packages.*.test.script"
              ];
              pythonPackageBuilder = [
                "packages.*.name"
                "packages.*.version"
                "packages.*.source.git"
                "packages.*.source.patches"
                "packages.*.build.pythonPackageBuilder.enable"
                "packages.*.build.pythonPackageBuilder.requirements.build-system"
                "packages.*.build.pythonPackageBuilder.requirements.dependencies"
                "packages.*.build.pythonPackageBuilder.requirements.optional-dependencies"
                "packages.*.build.pythonPackageBuilder.importsCheck"
                "packages.*.build.pythonPackageBuilder.relaxDeps"
                "packages.*.build.pythonPackageBuilder.disabledTests"
                "packages.*.test.script"
              ];
            };

            # Evaluation check: show warnings first, then throw on failed assertions
            _module.check =
              if showWarnings then
                if failedAssertions != [ ] then throw "\nFailed assertions:\n${assertionMessages}" else true
              else
                true;
          };
      }
    );
  };
}
