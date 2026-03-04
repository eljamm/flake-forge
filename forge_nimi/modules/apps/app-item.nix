{
  lib,
  inputs,
  config,
  pkgs,
  ...
}:
{
  options = {
    # General configuration
    name = lib.mkOption {
      type = lib.types.str;
      default = "my-application";
    };
    version = lib.mkOption {
      type = lib.types.str;
      default = "1.0.0";
    };
    description = lib.mkOption {
      type = lib.types.str;
      default = "";
    };
    usage = lib.mkOption {
      type = lib.types.str;
      default = "";
      description = "Application usage description in markdown format.";
    };

    # Portable services configuration (replaces programs)
    services = lib.mkOption {
      type = lib.types.lazyAttrsOf (
        lib.types.submodule {
          options = {
            process = {
              argv = lib.mkOption {
                type = lib.types.listOf (lib.types.str || lib.types.path);
                description = "Command filename and arguments for starting this service.";
                example = lib.literalExpression ''[ (lib.getExe pkgs.hello) "--greeting" "Hello" ]'';
              };
            };
            configData = lib.mkOption {
              type = lib.types.lazyAttrsOf (
                lib.types.submodule {
                  options = {
                    text = lib.mkOption {
                      type = lib.types.nullOr lib.types.str;
                      default = null;
                    };
                    source = lib.mkOption {
                      type = lib.types.nullOr lib.types.path;
                      default = null;
                    };
                  };
                }
              );
              default = { };
              description = "Configuration data files for the service.";
            };
          };
        }
      );
      default = { };
      description = ''
        Services to run inside the nimi runtime.

        Each attribute defines a named modular service: a reusable, composable module
        that you can import, extend, and tailor for each instance.
      '';
      example = lib.literalExpression ''
        {
          hello = {
            process.argv = [ (lib.getExe pkgs.hello) "--greeting" "Hello" ];
          };
        }
      '';
    };

    # Container configuration using Nimi
    containers = lib.mkOption {
      type = lib.types.submodule {
        imports = [ ./containers ];
        _module.args.app = config;
        _module.args.pkgs = pkgs;
        _module.args.inputs = inputs;
      };
      default = { };
      description = "Container configuration using Nimi.";
    };

    # NixOS configuration (renamed from vm)
    nixos = lib.mkOption {
      type = lib.types.submodule {
        imports = [ ./vm ];
        _module.args.app = config;
        _module.args.inputs = inputs;
      };
      default = { };
      description = "NixOS configuration using Nimi.";
    };
  };
}
