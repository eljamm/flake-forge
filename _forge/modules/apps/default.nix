{
  lib,
  inputs,
  config,
  pkgs,
  ...
}:

let
  cfg = config.forge;
in

{
  imports = [
    ../assertions-warnings.nix
  ];

  options = {
    options.packages = lib.mkOption {
      type = lib.types.anything;
      default = { };
      description = "Contains attributes for debugging and development.";
    };

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
            imports = [ ./app.nix ];
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
        appPassthru =
          # finalApp parameter is currently not used in this function
          app: finalApp:
          { }
          // lib.optionalAttrs app.containers.enable { containers = app.containers.build; }
          // lib.optionalAttrs app.vm.enable { vm = app.containers.build; };

        shellBundle =
          app:
          let
            appDrv = pkgs.symlinkJoin {
              name = "${app.name}-${app.version}";
              paths = app.programs.requirements;
            };
          in
          appDrv.overrideAttrs (oldAttrs: {
            passthru = oldAttrs.passthru or { } // appPassthru app appDrv;
          });

        allApps = lib.listToAttrs (
          map (app: {
            name = "${app.name}";
            value = shellBundle app;
          }) cfg.apps
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
