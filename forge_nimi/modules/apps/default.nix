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
                  # Handle both nixos and vm for backward compatibility
                  nixosConfig = app.nixos or app.vm or { };
                  # Handle both new containers settings and old images format
                  containersConfig = app.containers or { };
                in
                appDrv.overrideAttrs (
                  _: oldAttrs: {
                    passthru =
                      oldAttrs.passthru or { }
                      // lib.optionalAttrs (containersConfig.enable or false) { containers = containersConfig.build; }
                      // lib.optionalAttrs (nixosConfig.enable or false) { nixos = nixosConfig.build; };
                  }
                );

              allApps = lib.listToAttrs (
                map (app: {
                  name = "${app.name}";
                  value = shellBundle app;
                }) config.forge.apps
              );

              # Generate additional outputs for VM and containers
              additionalOutputs =
                let
                  mkVmOutput =
                    app:
                    if (app.nixos or app.vm or { }).enable or false then
                      let
                        vmConfig = app.nixos or app.vm or { };
                      in
                      [
                        {
                          name = "${app.name}.vm";
                          value = vmConfig.build;
                        }
                      ]
                    else
                      [ ];
                  mkContainersOutput =
                    app:
                    if (app.containers or { }).enable or false then
                      [
                        {
                          name = "${app.name}.containers";
                          value = (app.containers or { }).build;
                        }
                      ]
                    else
                      [ ];
                in
                lib.flatten (map (app: mkVmOutput app ++ mkContainersOutput app) config.forge.apps);
            in
            allApps // lib.listToAttrs additionalOutputs;

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
              # Legacy containers format (backward compatibility)
              "apps.*.containers.images"
              "apps.*.containers.composeFile"
            ];
            # Legacy vm option (backward compatibility - maps to nixos)
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
