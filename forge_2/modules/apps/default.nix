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
          forge_2 = {
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
              shellBundle =
                app:
                let
                  appDrv = pkgs.symlinkJoin {
                    name = "${app.name}-${app.version}";
                    paths = [ ];
                  };
                in
                appDrv.overrideAttrs (
                  _: oldAttrs: {
                    passthru =
                      oldAttrs.passthru or { }
                      // lib.optionalAttrs app.containers.enable { containers = app.containers.build; }
                      // lib.optionalAttrs app.nixos.enable { vm = app.nixos.build; };
                  }
                );

              allApps = lib.listToAttrs (
                map (app: {
                  name = "${app.name}";
                  value = shellBundle app;
                }) config.forge_2.apps
              );
            in
            allApps;

          forge_2.appsFilter = lib.mkDefault {
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
