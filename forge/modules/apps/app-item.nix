{
  lib,
  inputs,
  config,
  pkgs,

  nimi,
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

    # Portable services configuration (replaces programs)
    services = lib.mkOption {
      type = lib.types.lazyAttrsOf {
        # TODO: can't we just re-use this from Nixpkgs?
        imports = [ ./modular-services ];
        _module.args.app = config;
        _module.args.pkgs = pkgs;
        _module.args.nimi = nimi;
      };
      default = { };
      description = "Portable service definitions using NixOS modular services.";
      example = lib.literalExpression ''
        {
          my-service = {
            process.argv = [ (lib.getExe pkgs.mypkgs.my-package) "--flag" ];
            configData."config.conf" = { text = "port=8080"; };
            requirements = [ pkgs.mypkgs.my-package ];
          };
        }
      '';
    };

    # NixOS/VM configuration
    nixos = lib.mkOption {
      type = lib.types.submodule {
        imports = [ ./nixos ];
        _module.args.app = config;
        _module.args.inputs = inputs;
      };
      default = { };
      description = ""; # TODO:
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
