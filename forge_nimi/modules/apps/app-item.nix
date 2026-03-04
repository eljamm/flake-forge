{
  lib,
  inputs,
  config,
  pkgs,
  ...
}:
{
  options = {
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
      type = lib.types.attrsOf (
        lib.types.submodule {
          options = {
            process = {
              argv = lib.mkOption {
                type = lib.types.listOf lib.types.str;
                default = [ ];
                description = "Command and arguments to execute the service.";
                example = [
                  "${lib.getExe pkgs.hello}"
                  "--help"
                ];
              };
            };
            configData = lib.mkOption {
              type = lib.types.attrsOf (
                lib.types.submodule {
                  options = {
                    text = lib.mkOption {
                      type = lib.types.str;
                      description = "Text content of the config file.";
                    };
                  };
                }
              );
              default = { };
              description = "Configuration files to create for the service.";
              example = lib.literalExpression ''
                {
                  "config.conf" = {
                    text = "port=8080";
                  };
                }
              '';
            };
            requirements = lib.mkOption {
              type = lib.types.listOf lib.types.package;
              default = [ ];
              description = "Nix packages required by this service.";
            };
          };
        }
      );
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

    # Programs shell configuration (legacy, for backward compatibility)
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

    # Container configuration using Nimi
    containers = lib.mkOption {
      type = lib.types.submodule {
        imports = [ ./containers ];
        _module.args.app = config;
        _module.args.pkgs = pkgs;
        _module.args.inputs = inputs;
      };
      default = { };
      description = ""; # TODO:
    };

    # NixOS/VM configuration (renamed from vm to nixos)
    nixos = lib.mkOption {
      type = lib.types.submodule {
        imports = [ ./nixos ];
        _module.args.app = config;
        _module.args.inputs = inputs;
      };
      default = { };
      description = ""; # TODO:
    };
  };
}
