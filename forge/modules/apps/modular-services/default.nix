{
  lib,

  nimi,
  pkgs,
  ...
}:
{
  options = {
    imports = lib.mkOption {
      type = lib.types.listOf lib.types.path;
      default = [ ];
      description = "List of modular service modules to import.";
      example = lib.literalExpression ''
        [ pkgs.mypkgs.mox.serviceModule ]
      '';
    };
    process = {
      argv = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ ];
        description = "Command and arguments to execute the service.";
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

    build = lib.mkOption {
      internal = true;
      readOnly = true;
      type = lib.types.package;
      default = nimi.mkNimiBin {
        services.mox = {
          imports = [ pkgs.mox.services.default ];
          mox = {
            hostname = "mail";
            user = "admin@example.com";
          };
        };
      };
      description = ""; # TODO:
    };
  };
}
