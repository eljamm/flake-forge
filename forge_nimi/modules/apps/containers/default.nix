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
                copyToRoot = lib.mkOption {
                  type = lib.types.listOf lib.types.package;
                  default = [ ];
                  description = "A list of derivations to copy to the image root directory.";
                };
                fromImage = lib.mkOption {
                  type = lib.types.nullOr lib.types.path;
                  default = null;
                  description = "An image that is used as base image.";
                };
                maxLayers = lib.mkOption {
                  type = lib.types.int;
                  default = 1;
                  description = "The maximum number of layers to create.";
                };
              };
            };
            default = { };
            description = "Nimi container settings.";
            example = lib.literalExpression ''
              {
                name = "my-container";
                tag = "v1.0";
                copyToRoot = [ pkgs.bash pkgs.coreutils ];
              }
            '';
          };
        };
      };
      default = { };
      description = "Nimi settings for container generation.";
      example = lib.literalExpression ''
        {
          container = {
            name = "my-app";
            tag = "latest";
          };
        }
      '';
    };

    extraConfig = lib.mkOption {
      type = lib.types.attrsOf lib.types.anything;
      default = { };
      description = "Arbitrary additional configuration for the container.";
      example = lib.literalExpression ''
        {
          # Additional nix2container config
        }
      '';
    };

    build = lib.mkOption {
      internal = true;
      readOnly = true;
      type = lib.types.package;
      default =
        let
          nimi = inputs.nimi;
        in
        pkgs.runCommand "${app.name}-${app.version}-containers" { } ''
          echo "Nimi container output placeholder"
          mkdir -p $out
        '';
      description = ""; # TODO:
    };
  };
}
