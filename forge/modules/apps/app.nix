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

    # Programs shell configuration
    programs = {
      enable = lib.mkEnableOption ''
        Programs bundle output.
      '';
      requirements = lib.mkOption {
        type = lib.types.listOf lib.types.package;
        default = [ ];
        description = ""; # TODO:
      };
    };

    # Container configuration
    containers = lib.mkOption {
      type = lib.types.submodule {
        imports = [ ./containers ];
        _module.args.app = config;
        _module.args.pkgs = pkgs;
      };
      default = { };
      description = ""; # TODO:
    };

    # Virtual machine
    vm = lib.mkOption {
      type = lib.types.submodule {
        imports = [ ./vm ];
        _module.args.app = config;
        _module.args.inputs = inputs;
      };
      default = { };
      description = ""; # TODO:
    };
  };
}
