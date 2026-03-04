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
              type = lib.types.listOf (
                lib.types.submodule {
                  imports = [ ./app-item.nix ];
                  _module.args.pkgs = pkgs;
                  _module.args.inputs = inputs;
                }
              );
            };
          };
        };

        config = {
          packages =
            let
              aggregateRequirements =
                app:
                let
                  # Get requirements from legacy programs option
                  programReqs = app.programs.requirements or [ ];
                  # Get requirements from new services option
                  serviceReqs = lib.flatten (
                    lib.mapAttrsToList (name: service: service.requirements or [ ]) (app.services or { })
                  );
                in
                programReqs ++ serviceReqs;

              shellBundle =
                app:
                let
                  reqs = aggregateRequirements app;
                  appDrv = pkgs.symlinkJoin {
                    name = "${app.name}-${app.version}";
                    paths = reqs;
                  };
                in
                appDrv.overrideAttrs (
                  _: oldAttrs: {
                    passthru =
                      oldAttrs.passthru or { }
                      // lib.optionalAttrs (app.containers.enable or false) { containers = app.containers.build; }
                      // lib.optionalAttrs (app.nixos.enable or false) { nixos = app.nixos.build; };
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
            # Legacy programs option (backward compatibility)
            programs = [
              "apps.*.name"
              "apps.*.version"
              "apps.*.programs.enable"
              "apps.*.programs.requirements"
            ];
            # New portable services option
            services = [
              "apps.*.name"
              "apps.*.version"
              "apps.*.services"
            ];
            containers = [
              "apps.*.name"
              "apps.*.version"
              "apps.*.containers.enable"
              "apps.*.containers.settings"
              "apps.*.containers.extraConfig"
            ];
            nixos = [
              "apps.*.name"
              "apps.*.version"
              "apps.*.nixos.enable"
              "apps.*.nixos.name"
              "apps.*.nixos.settings"
              "apps.*.nixos.extraConfig"
              "apps.*.nixos.vm.cores"
              "apps.*.nixos.vm.memorySize"
              "apps.*.nixos.vm.diskSize"
              "apps.*.nixos.vm.ports"
            ];
          };
        };
      }
    );
  };
}
