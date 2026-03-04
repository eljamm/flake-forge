{
  lib,
  pkgs,
  inputs,
  app,
  ...
}:
{
  options = {
    enable = lib.mkEnableOption ''
      Container images output using Nimi.
    '';

    settings = lib.mkOption {
      type = lib.types.submodule {
        options = {
          container = lib.mkOption {
            type = lib.types.submodule {
              options = {
                name = lib.mkOption {
                  type = lib.types.str;
                  default = "nimi-container";
                  description = "The name of the generated image.";
                };
                tag = lib.mkOption {
                  type = lib.types.str;
                  default = "latest";
                  description = "The tag for the generated image.";
                };
                fromImage = lib.mkOption {
                  type = lib.types.nullOr lib.types.path;
                  default = null;
                  description = "An image that is used as base image.";
                };
                copyToRoot = lib.mkOption {
                  type = lib.types.listOf lib.types.path;
                  default = [ ];
                  description = "A list of derivations to copy to the image root.";
                };
                imageConfig = lib.mkOption {
                  type = lib.types.attrsOf lib.types.anything;
                  default = { };
                  description = "OCI image configuration.";
                };
                maxLayers = lib.mkOption {
                  type = lib.types.int;
                  default = 1;
                  description = "Maximum number of layers to create.";
                };
              };
            };
            default = { };
            description = "Nimi container settings.";
          };
        };
      };
      default = { };
      description = "Nimi container settings.";
      example = lib.literalExpression ''
        {
          container = {
            name = "my-app";
            tag = "v1.0";
            copyToRoot = [ pkgs.hello ];
          };
        }
      '';
    };

    extraConfig = lib.mkOption {
      type = lib.types.attrsOf lib.types.anything;
      default = { };
      description = "Arbitrary additional system specific configuration.";
    };

    build = lib.mkOption {
      internal = true;
      readOnly = true;
      type = lib.types.package;
      description = "Built container image.";
    };
  };

  config = lib.mkIf app.containers.enable {
    build =
      let
        cfg = app.containers;
        containerSettings = cfg.settings.container or { };
        nimi = inputs.nimi;

        image = nimi.outPath + "/bin/nimi";
      in
      pkgs.runCommand "${app.name}-container" { } ''
        echo "Building container with Nimi settings"
        mkdir -p $out
      '';
  };
}
