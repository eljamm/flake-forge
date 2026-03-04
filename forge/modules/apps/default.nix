{
  lib,
  inputs,
  flake-parts-lib,
  ...
}:

let
  inherit (flake-parts-lib)
    mkPerSystemOption
    ;
in
{
  imports = [
    ../assertions-warnings.nix
  ];

  options = {
    perSystem = mkPerSystemOption (
      {
        config,
        pkgs,
        nimi,
        ...
      }:
      {
        options = {
          forge = {
            appsFilter = lib.mkOption {
              internal = true;
              type = lib.types.attrsOf (lib.types.listOf lib.types.str);
              default = { };
              description = "Defines which options are relevant for each app output type.";
            };

            apps = lib.mkOption {
              default = [ ];
              description = "List of applications.";
              # TODO: attrs instead of list?
              type = lib.types.listOf (
                lib.types.submodule {
                  imports = [ ./app-item.nix ];
                  _module.args.pkgs = pkgs;
                  _module.args.nimi = nimi;
                  _module.args.inputs = inputs;
                }
              );
            };
          };
        };

        config = {
          packages =
            let
              shellBundle =
                app:
                let
                  appDrv = pkgs.symlinkJoin {
                    name = "${app.name}-${app.version}";
                    paths = app.programs.requirements;
                  };
                in
                appDrv.overrideAttrs (
                  _: oldAttrs: {
                    passthru =
                      oldAttrs.passthru or { }
                      // lib.optionalAttrs app.containers.enable { containers = app.containers.build; }
                      // lib.optionalAttrs app.vm.enable { vm = app.containers.build; }
                      // lib.optionalAttrs app.nixos.enable {
                        nimi = nimi.mkContainerImage {
                          services = app.services;
                        };
                      };
                  }
                );

              allApps = lib.listToAttrs (
                map (app: {
                  name = "${app.name}";
                  value = shellBundle app;
                }) config.forge.apps
              );
            in
            allApps;

          forge.appsFilter = lib.mkDefault {
            programs = [
              "apps.*.name"
              "apps.*.version"
              "apps.*.programs.enable"
              "apps.*.programs.requirements"
            ];
            containers = [
              "apps.*.name"
              "apps.*.version"
              "apps.*.containers.enable"
              "apps.*.containers.images"
              "apps.*.containers.composeFile"
            ];
            vm = [
              "apps.*.name"
              "apps.*.version"
              "apps.*.vm.enable"
              "apps.*.vm.name"
              "apps.*.vm.requirements"
              "apps.*.vm.config.system"
              "apps.*.vm.config.ports"
              "apps.*.vm.config.cores"
              "apps.*.vm.config.memorySize"
              "apps.*.vm.config.diskSize"
            ];
          };
        };
      }
    );
  };
}
